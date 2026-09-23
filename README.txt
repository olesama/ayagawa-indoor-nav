館内ナビ｜イオンモール綾川 - アプリ化版（PWA）
=================================================

これはブラウザで動くWeb版を「ホーム画面に追加できるアプリ」にした版です。

入っているもの
- index.html : アプリ本体
- manifest.webmanifest : アプリ名・アイコン・起動設定
- service-worker.js : オフライン対応
- icon-192.png / icon-512.png / apple-touch-icon.png : アプリアイコン
- .nojekyll : GitHub Pages向け

iPhoneでアプリとして使うには
1. このフォルダをGitHub Pages / Cloudflare Pages / Replit等で公開
2. Safariで公開URLを開く
3. 共有ボタン → 「ホーム画面に追加」
4. ホーム画面の「館内ナビ」アイコンから起動

この方法ならApp Store審査なしでアプリのように使えます。

将来App Storeに正式公開する場合
- このPWAをCapacitor等でiOSアプリ化
- Mac + Xcode + Apple Developer Programで署名・提出
