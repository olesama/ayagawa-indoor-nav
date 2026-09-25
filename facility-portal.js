(function(){
"use strict";

// Supabaseの Project URL と Publishable key を設定後、本番チャットが有効になります。
const CONFIG={url:"https://odlybanyfxymkegeyjhp.supabase.co",publishableKey:"sb_publishable_sbr_VADLwB-cNKnnDggf8A_cAOcCLCh"};
let db=null,user=null,profile=null,currentConversation=null,channel=null;
const $=id=>document.getElementById(id);
const esc=s=>String(s??"").replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
const configured=()=>/^https:\/\/.+\.supabase\.co$/.test(CONFIG.url)&&CONFIG.publishableKey.length>20;

window.openFacilityPortal=async function(){
  if(typeof openInfoPage==="function")openInfoPage("menu");
  $("infoTitle").textContent="施設担当者ポータル";
  $("infoBody").innerHTML='<div id="facilityPortal" class="portalShell"></div>';
  if(!configured())return renderSetup();
  if(!window.supabase)return renderError("通信機能の読み込みに失敗しました。再読み込みしてください。");
  db=window.supabase.createClient(CONFIG.url,CONFIG.publishableKey,{auth:{persistSession:true,detectSessionInUrl:true}});
  const {data}=await db.auth.getSession();user=data.session?.user||null;
  if(!user)return renderLogin();
  await loadProfile();
};

function renderSetup(){
  $("facilityPortal").innerHTML=`<div class="portalStatus"><b>チャット接続準備中</b><br>画面と安全なデータベース設計は追加済みです。Supabaseの接続情報を設定すると、施設アカウント・リアルタイムチャット・画像添付・修正依頼が有効になります。</div><button class="primaryAction" disabled>現在はログインできません</button>`;
}
function renderError(message){$("facilityPortal").innerHTML=`<div class="portalStatus">${esc(message)}</div>`}
function renderLogin(){
  $("facilityPortal").innerHTML=`<div class="portalStatus">施設から登録された担当者と、館内ナビ管理者だけが利用できます。ログイン用リンクをメールで受け取ります。</div><form onsubmit="facilityPortalLogin(event)"><div class="portalField"><label>仕事用メールアドレス</label><input id="portalEmail" type="email" required autocomplete="email" placeholder="name@example.co.jp"></div><button class="primaryAction" type="submit">ログインリンクを受け取る</button></form><p id="portalNotice" class="small"></p>`;
}
window.facilityPortalLogin=async function(e){
  e.preventDefault();const email=$("portalEmail").value.trim(),button=e.submitter;button.disabled=true;
  const {error}=await db.auth.signInWithOtp({email,options:{emailRedirectTo:location.origin+location.pathname}});
  $("portalNotice").textContent=error?"送信できませんでした："+error.message:"メールを送りました。届いたログインリンクを開いてください。";button.disabled=false;
};
async function loadProfile(){
  const {data,error}=await db.from("profiles").select("id,email,display_name,role,facility_id,facilities(name)").eq("id",user.id).single();
  if(error||!data)return renderError("アカウントの施設登録が完了していません。管理者へ連絡してください。");
  profile=data;if(profile.role==="pending")return renderError("このアカウントは承認待ちです。管理者が施設を確認すると利用できます。");
  renderHome();await loadConversations();subscribe();
}
function renderHome(){
  const facility=profile.facilities?.name||"全施設";
  $("facilityPortal").innerHTML=`<div class="portalStatus"><b>${esc(profile.display_name||profile.email)}</b><br>${esc(facility)} ／ ${profile.role==="admin"?"管理者":"施設担当者"}</div><div class="portalTabs"><button id="tabChats" class="active" onclick="portalTab('chats')">チャット <span id="portalUnread"></span></button><button id="tabRequest" onclick="portalTab('request')">修正依頼</button><button onclick="enablePortalNotifications()">通知をON</button><button onclick="portalLogout()">ログアウト</button></div><div id="portalView"></div>`;
}
window.portalTab=function(tab){
  ["tabChats","tabRequest"].forEach(id=>$(id)?.classList.remove("active"));
  if(tab==="request"){$("tabRequest").classList.add("active");renderRequestForm();}
  else{$("tabChats").classList.add("active");loadConversations();}
};
async function loadConversations(){
  currentConversation=null;const view=$("portalView");if(!view)return;view.innerHTML='<p class="small">読み込み中…</p>';
  let q=db.from("conversations").select("id,subject,facility_id,updated_at,facilities(name)").order("updated_at",{ascending:false});
  if(profile.role!=="admin")q=q.eq("facility_id",profile.facility_id);
  let {data,error}=await q;if(error)return renderError(error.message);
  if(!data.length&&profile.role!=="admin"){
    const made=await db.from("conversations").insert({facility_id:profile.facility_id,subject:"館内ナビ運営チャット",created_by:user.id}).select("id,subject,facility_id,updated_at,facilities(name)").single();
    if(!made.error)data=[made.data];
  }
  view.innerHTML=data.length?`<div class="chatList">${data.map(x=>`<button class="chatThread" onclick="openPortalChat('${x.id}')"><b>${esc(x.facilities?.name||"施設")}｜${esc(x.subject)}</b><small>更新 ${new Date(x.updated_at).toLocaleString("ja-JP")}</small></button>`).join("")}</div>`:'<p class="small">会話はまだありません。</p>';
}
window.openPortalChat=async function(id){
  currentConversation=id;const view=$("portalView");view.innerHTML='<p class="small">メッセージを読み込み中…</p>';
  const {data,error}=await db.from("messages").select("id,sender_id,body,attachment_path,attachment_name,created_at,profiles(display_name,role)").eq("conversation_id",id).order("created_at");
  if(error){view.innerHTML=`<p>${esc(error.message)}</p>`;return}
  view.innerHTML=`<button class="chip" onclick="loadConversations()">← 会話一覧</button><div id="portalMessages" class="messages">${data.map(messageHTML).join("")}</div><div class="portalField"><label>写真・フロアマップ（10MBまで）</label><input id="portalFile" type="file" accept="image/*,.pdf"></div><div class="chatComposer"><textarea id="portalMessage" placeholder="メッセージを入力"></textarea><button onclick="sendPortalMessage()">送信</button></div>`;scrollMessages();await markRead();
};
function messageHTML(m){
  const mine=m.sender_id===user.id,who=m.profiles?.display_name||(m.profiles?.role==="admin"?"館内ナビ管理者":"施設担当者");
  const file=m.attachment_path?`<a class="attachmentLink" href="#" onclick="openPortalFile('${esc(m.attachment_path)}');return false">📎 ${esc(m.attachment_name||"添付ファイル")}</a>`:"";
  return `<div class="bubble ${mine?"mine":""}">${esc(m.body).replace(/\n/g,"<br>")}${file}<small>${esc(who)}・${new Date(m.created_at).toLocaleString("ja-JP")}</small></div>`;
}
async function markRead(){await db.from("conversation_reads").upsert({conversation_id:currentConversation,user_id:user.id,last_read_at:new Date().toISOString()});}
window.sendPortalMessage=async function(){
  const body=$("portalMessage").value.trim(),file=$("portalFile").files[0];if(!body&&!file)return;
  if(file&&file.size>10*1024*1024)return alert("添付は10MBまでです。");
  let path=null;if(file){path=`${profile.facility_id}/${currentConversation}/${crypto.randomUUID()}-${file.name.replace(/[^a-zA-Z0-9._-]/g,"_")}`;const up=await db.storage.from("chat-files").upload(path,file);if(up.error)return alert("添付できませんでした："+up.error.message)}
  const sent=await db.from("messages").insert({conversation_id:currentConversation,sender_id:user.id,body,attachment_path:path,attachment_name:file?.name||null});if(sent.error)return alert("送信できませんでした："+sent.error.message);
  $("portalMessage").value="";$("portalFile").value="";await openPortalChat(currentConversation);
};
window.openPortalFile=async function(path){const {data,error}=await db.storage.from("chat-files").createSignedUrl(path,60);if(error)return alert("ファイルを開けませんでした。");open(data.signedUrl,"_blank","noopener")};
function renderRequestForm(){
  $("portalView").innerHTML=`<form onsubmit="submitPortalRequest(event)"><div class="portalField"><label>依頼の種類</label><select id="requestType"><option>店舗情報の変更</option><option>経路・距離の修正</option><option>トイレ・設備の変更</option><option>フロアマップ更新</option><option>その他</option></select></div><div class="portalField"><label>件名</label><input id="requestTitle" required maxlength="100"></div><div class="portalField"><label>詳しい内容</label><textarea id="requestDetail" required maxlength="3000"></textarea></div><div class="portalField"><label>参考写真・マップ</label><input id="requestFile" type="file" accept="image/*,.pdf"></div><button class="primaryAction" type="submit">修正依頼を送る</button></form><div id="requestResult"></div>`;
}
window.submitPortalRequest=async function(e){
  e.preventDefault();const file=$("requestFile").files[0];if(file&&file.size>10*1024*1024)return alert("添付は10MBまでです。");
  let path=null;if(file){path=`${profile.facility_id}/requests/${crypto.randomUUID()}-${file.name.replace(/[^a-zA-Z0-9._-]/g,"_")}`;const up=await db.storage.from("chat-files").upload(path,file);if(up.error)return alert(up.error.message)}
  const {error}=await db.from("change_requests").insert({facility_id:profile.facility_id,created_by:user.id,type:$("requestType").value,title:$("requestTitle").value.trim(),details:$("requestDetail").value.trim(),attachment_path:path,status:"new"});
  $("requestResult").innerHTML=error?`<p>送信できませんでした：${esc(error.message)}</p>`:'<div class="portalStatus"><b>送信しました。</b><br>管理者が確認後、チャットで連絡します。</div>';if(!error)e.target.reset();
};
function subscribe(){
  if(channel)db.removeChannel(channel);channel=db.channel("facility-portal").on("postgres_changes",{event:"INSERT",schema:"public",table:"messages"},payload=>{
    if(payload.new.sender_id===user.id)return;if(currentConversation===payload.new.conversation_id)openPortalChat(currentConversation);else $("portalUnread").innerHTML='<span class="unreadDot">新着</span>';
    if(Notification.permission==="granted")new Notification("館内ナビ｜新着メッセージ",{body:"施設チャットに新しいメッセージがあります。",icon:"./icon-192.png"});
  }).subscribe();
}
window.enablePortalNotifications=async function(){if(!("Notification" in window))return alert("この端末では通知を利用できません。");const result=await Notification.requestPermission();alert(result==="granted"?"通知を有効にしました。":"通知が許可されませんでした。")};
window.portalLogout=async function(){if(channel)await db.removeChannel(channel);await db.auth.signOut();user=profile=null;renderLogin()};
function scrollMessages(){const el=$("portalMessages");if(el)el.scrollTop=el.scrollHeight}
})();
