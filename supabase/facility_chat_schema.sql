-- 館内ナビ 施設担当者ポータル
-- Supabase SQL Editorで実行後、最後のADMIN_EMAILを実際の管理者メールに変更してください。

create extension if not exists pgcrypto;

create table if not exists public.facilities (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  status text not null default 'trial' check (status in ('trial','active','paused')),
  created_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text,
  role text not null default 'pending' check (role in ('pending','facility','admin')),
  facility_id uuid references public.facilities(id),
  created_at timestamptz not null default now()
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  facility_id uuid not null references public.facilities(id) on delete cascade,
  subject text not null default '館内ナビ運営チャット',
  created_by uuid not null references public.profiles(id),
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.messages (
  id bigint generated always as identity primary key,
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id),
  body text not null default '' check (char_length(body) <= 5000),
  attachment_path text,
  attachment_name text,
  created_at timestamptz not null default now(),
  check (body <> '' or attachment_path is not null)
);

create table if not exists public.conversation_reads (
  conversation_id uuid references public.conversations(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  last_read_at timestamptz not null default now(),
  primary key (conversation_id,user_id)
);

create table if not exists public.change_requests (
  id uuid primary key default gen_random_uuid(),
  facility_id uuid not null references public.facilities(id) on delete cascade,
  created_by uuid not null references public.profiles(id),
  type text not null,
  title text not null check (char_length(title) <= 100),
  details text not null check (char_length(details) <= 3000),
  attachment_path text,
  status text not null default 'new' check (status in ('new','checking','working','completed','rejected')),
  admin_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.profiles where id=auth.uid() and role='admin') $$;

create or replace function public.my_facility_id()
returns uuid language sql stable security definer set search_path=public
as $$ select facility_id from public.profiles where id=auth.uid() $$;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public
as $$ begin
  insert into public.profiles(id,email,display_name)
  values(new.id,coalesce(new.email,''),coalesce(new.raw_user_meta_data->>'display_name',split_part(coalesce(new.email,''),'@',1)));
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create or replace function public.touch_conversation()
returns trigger language plpgsql security definer set search_path=public
as $$ begin update public.conversations set updated_at=now() where id=new.conversation_id; return new; end $$;
drop trigger if exists on_message_created on public.messages;
create trigger on_message_created after insert on public.messages for each row execute procedure public.touch_conversation();

alter table public.facilities enable row level security;
alter table public.profiles enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.conversation_reads enable row level security;
alter table public.change_requests enable row level security;

create policy "facility members read facility" on public.facilities for select to authenticated using (id=public.my_facility_id() or public.is_admin());
create policy "members read relevant profiles" on public.profiles for select to authenticated using (id=auth.uid() or facility_id=public.my_facility_id() or public.is_admin());
create policy "members read conversations" on public.conversations for select to authenticated using (facility_id=public.my_facility_id() or public.is_admin());
create policy "facility starts conversation" on public.conversations for insert to authenticated with check ((facility_id=public.my_facility_id() and created_by=auth.uid()) or public.is_admin());
create policy "members read messages" on public.messages for select to authenticated using (exists(select 1 from public.conversations c where c.id=conversation_id and (c.facility_id=public.my_facility_id() or public.is_admin())));
create policy "members send messages" on public.messages for insert to authenticated with check (sender_id=auth.uid() and exists(select 1 from public.conversations c where c.id=conversation_id and (c.facility_id=public.my_facility_id() or public.is_admin())));
create policy "members manage own reads" on public.conversation_reads for all to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy "members read requests" on public.change_requests for select to authenticated using (facility_id=public.my_facility_id() or public.is_admin());
create policy "facility creates requests" on public.change_requests for insert to authenticated with check (created_by=auth.uid() and (facility_id=public.my_facility_id() or public.is_admin()));
create policy "admin updates requests" on public.change_requests for update to authenticated using (public.is_admin()) with check (public.is_admin());

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('chat-files','chat-files',false,10485760,array['image/jpeg','image/png','image/webp','image/heic','application/pdf'])
on conflict(id) do update set public=false,file_size_limit=10485760;

create policy "members read facility files" on storage.objects for select to authenticated using (
  bucket_id='chat-files' and ((storage.foldername(name))[1]=public.my_facility_id()::text or public.is_admin())
);
create policy "members upload facility files" on storage.objects for insert to authenticated with check (
  bucket_id='chat-files' and ((storage.foldername(name))[1]=public.my_facility_id()::text or public.is_admin())
);

alter publication supabase_realtime add table public.messages;

-- 初期設定例：先に管理者がメールリンクで一度ログインしてprofilesを作成します。
-- update public.profiles set role='admin',display_name='館内ナビ管理者' where email='ADMIN_EMAIL';
-- 施設作成：insert into public.facilities(name,status) values('イオンモール綾川','trial') returning id;
-- 担当者承認：update public.profiles set role='facility',facility_id='上で返ったUUID' where email='担当者メール';
