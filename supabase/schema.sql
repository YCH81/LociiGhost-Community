-- =============================================================================
-- LociiGhost Community — Supabase schema (W1 baseline)
-- =============================================================================
-- 在 Supabase Dashboard → SQL Editor 整份貼上執行一次即可。
-- 已 idempotent：重複跑同一份不會壞，會覆蓋 policy / 重建 trigger。
--
-- 表：
--   profiles     — 使用者公開資料（display_name 等），auto-created on signup
--   mushrooms    — 皮克敏菇點（紅/黃/藍/白/紫/灰/岩/翼/虹）
--   postcards    — 明信片（含照片）
--   routes       — 路線檔案分享（含 GPX）
--
-- Storage buckets：
--   postcard-photos  — 公開讀，登入寫，5MB cap
--   route-files      — 公開讀，登入寫，1MB cap
--
-- Auth：Supabase Auth 內建 auth.users 表，由 Apple Sign-In 自動填。
--       我們的所有 *_uploader_id 都 FK 到 auth.users(id)。
-- =============================================================================

-- ─── Extensions ────────────────────────────────────────────────────────────
create extension if not exists "pgcrypto";   -- for gen_random_uuid()

-- =============================================================================
-- profiles：使用者公開展示資料
-- =============================================================================
create table if not exists public.profiles (
    id           uuid primary key references auth.users(id) on delete cascade,
    display_name text not null,
    created_at   timestamptz not null default now(),
    updated_at   timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- 公開可讀（任何人能看別人的暱稱、加入時間）
drop policy if exists "profiles_public_read" on public.profiles;
create policy "profiles_public_read"
    on public.profiles for select
    using (true);

-- 只能改自己的
drop policy if exists "profiles_owner_update" on public.profiles;
create policy "profiles_owner_update"
    on public.profiles for update
    using (auth.uid() = id)
    with check (auth.uid() = id);

-- 觸發器：新使用者註冊時自動建一筆 profile
-- 預設 display_name 是「飛人」+ UUID 前 4 碼，使用者可以後改
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.profiles (id, display_name)
    values (new.id, '飛人' || substr(new.id::text, 1, 4))
    on conflict (id) do nothing;
    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row
    execute function public.handle_new_user();

-- =============================================================================
-- mushrooms：菇點
-- =============================================================================
create table if not exists public.mushrooms (
    id             uuid primary key default gen_random_uuid(),
    -- Pikmin 種類，固定列舉避免 typo + 方便客戶端 filter
    mushroom_type  text not null
                   check (mushroom_type in (
                       'red', 'yellow', 'blue', 'white',
                       'purple', 'gray', 'rock', 'wing', 'rainbow'
                   )),
    name           text not null check (char_length(name) between 1 and 80),
    description    text check (char_length(description) <= 500),
    lat            double precision not null check (lat between -90 and 90),
    lng            double precision not null check (lng between -180 and 180),
    uploader_id    uuid not null references auth.users(id) on delete cascade,
    -- 上傳當下的 display name 快照。即使上傳者後來改名，這筆記錄保留原本名字。
    uploader_name  text not null,
    created_at     timestamptz not null default now(),
    updated_at     timestamptz not null default now()
);

create index if not exists mushrooms_lat_lng_idx on public.mushrooms (lat, lng);
create index if not exists mushrooms_type_idx on public.mushrooms (mushroom_type);
create index if not exists mushrooms_created_at_idx on public.mushrooms (created_at desc);
create index if not exists mushrooms_uploader_id_idx on public.mushrooms (uploader_id);

alter table public.mushrooms enable row level security;

drop policy if exists "mushrooms_public_read" on public.mushrooms;
create policy "mushrooms_public_read"
    on public.mushrooms for select
    using (true);

drop policy if exists "mushrooms_authenticated_insert" on public.mushrooms;
create policy "mushrooms_authenticated_insert"
    on public.mushrooms for insert
    with check (auth.uid() = uploader_id);

drop policy if exists "mushrooms_owner_update" on public.mushrooms;
create policy "mushrooms_owner_update"
    on public.mushrooms for update
    using (auth.uid() = uploader_id)
    with check (auth.uid() = uploader_id);

drop policy if exists "mushrooms_owner_delete" on public.mushrooms;
create policy "mushrooms_owner_delete"
    on public.mushrooms for delete
    using (auth.uid() = uploader_id);

-- =============================================================================
-- postcards：明信片
-- =============================================================================
create table if not exists public.postcards (
    id             uuid primary key default gen_random_uuid(),
    name           text not null check (char_length(name) between 1 and 80),
    description    text check (char_length(description) <= 1000),
    lat            double precision not null check (lat between -90 and 90),
    lng            double precision not null check (lng between -180 and 180),
    -- 照片路徑（相對於 postcard-photos bucket）。客戶端用
    --   supabase.storage.from('postcard-photos').getPublicUrl(photo_path)
    -- 拿公開 URL。允許 nullable so 純文字明信片也行。
    photo_path     text,
    uploader_id    uuid not null references auth.users(id) on delete cascade,
    uploader_name  text not null,
    created_at     timestamptz not null default now(),
    updated_at     timestamptz not null default now()
);

create index if not exists postcards_lat_lng_idx on public.postcards (lat, lng);
create index if not exists postcards_created_at_idx on public.postcards (created_at desc);
create index if not exists postcards_uploader_id_idx on public.postcards (uploader_id);

alter table public.postcards enable row level security;

drop policy if exists "postcards_public_read" on public.postcards;
create policy "postcards_public_read"
    on public.postcards for select
    using (true);

drop policy if exists "postcards_authenticated_insert" on public.postcards;
create policy "postcards_authenticated_insert"
    on public.postcards for insert
    with check (auth.uid() = uploader_id);

drop policy if exists "postcards_owner_update" on public.postcards;
create policy "postcards_owner_update"
    on public.postcards for update
    using (auth.uid() = uploader_id)
    with check (auth.uid() = uploader_id);

drop policy if exists "postcards_owner_delete" on public.postcards;
create policy "postcards_owner_delete"
    on public.postcards for delete
    using (auth.uid() = uploader_id);

-- =============================================================================
-- routes：路線檔案分享
-- =============================================================================
create table if not exists public.routes (
    id             uuid primary key default gen_random_uuid(),
    name           text not null check (char_length(name) between 1 and 100),
    -- 上傳者對路線的說明（建議目的地、注意事項、難度…）
    description    text check (char_length(description) <= 2000),
    -- GPX 檔案路徑（相對於 route-files bucket）
    gpx_path       text not null,
    -- 路線統計，客戶端解析 GPX 後填入。讓列表頁不用每次都下載 GPX
    -- 才能顯示「1163 點 / 8.4 km」。
    point_count    integer not null check (point_count >= 2),
    distance_m     double precision not null check (distance_m >= 0),
    -- 起點座標（讓列表按距離排序、預覽地圖 pin）
    start_lat      double precision not null check (start_lat between -90 and 90),
    start_lng      double precision not null check (start_lng between -180 and 180),
    uploader_id    uuid not null references auth.users(id) on delete cascade,
    uploader_name  text not null,
    created_at     timestamptz not null default now(),
    updated_at     timestamptz not null default now()
);

create index if not exists routes_start_lat_lng_idx on public.routes (start_lat, start_lng);
create index if not exists routes_created_at_idx on public.routes (created_at desc);
create index if not exists routes_uploader_id_idx on public.routes (uploader_id);

alter table public.routes enable row level security;

drop policy if exists "routes_public_read" on public.routes;
create policy "routes_public_read"
    on public.routes for select
    using (true);

drop policy if exists "routes_authenticated_insert" on public.routes;
create policy "routes_authenticated_insert"
    on public.routes for insert
    with check (auth.uid() = uploader_id);

drop policy if exists "routes_owner_update" on public.routes;
create policy "routes_owner_update"
    on public.routes for update
    using (auth.uid() = uploader_id)
    with check (auth.uid() = uploader_id);

drop policy if exists "routes_owner_delete" on public.routes;
create policy "routes_owner_delete"
    on public.routes for delete
    using (auth.uid() = uploader_id);

-- =============================================================================
-- updated_at 自動維護觸發器
-- =============================================================================
create or replace function public.tg_set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists tg_profiles_updated on public.profiles;
create trigger tg_profiles_updated
    before update on public.profiles
    for each row execute function public.tg_set_updated_at();

drop trigger if exists tg_mushrooms_updated on public.mushrooms;
create trigger tg_mushrooms_updated
    before update on public.mushrooms
    for each row execute function public.tg_set_updated_at();

drop trigger if exists tg_postcards_updated on public.postcards;
create trigger tg_postcards_updated
    before update on public.postcards
    for each row execute function public.tg_set_updated_at();

drop trigger if exists tg_routes_updated on public.routes;
create trigger tg_routes_updated
    before update on public.routes
    for each row execute function public.tg_set_updated_at();

-- =============================================================================
-- Storage buckets：postcard-photos + route-files
-- =============================================================================
-- 兩個 bucket 都是 public read，但 Storage RLS 規則限制 insert/delete。
-- 路徑慣例：每個 bucket 內檔案以「{uploader_id}/{uuid}.{ext}」存放，
-- 這樣 Storage RLS policy 可以用 storage.foldername(name)[1] 確認上傳者。

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
    'postcard-photos',
    'postcard-photos',
    true,
    5242880,    -- 5 MB cap
    array['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
on conflict (id) do update set
    public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
    'route-files',
    'route-files',
    true,
    1048576,    -- 1 MB cap (1163-pt GPX ~ 130KB，留 8x 餘地)
    array['application/gpx+xml', 'application/xml', 'text/xml']
)
on conflict (id) do update set
    public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

-- Storage RLS policies。Supabase 的 storage.objects 表已預設啟用 RLS。

-- postcard-photos
drop policy if exists "postcard_photos_public_read" on storage.objects;
create policy "postcard_photos_public_read"
    on storage.objects for select
    using (bucket_id = 'postcard-photos');

drop policy if exists "postcard_photos_owner_insert" on storage.objects;
create policy "postcard_photos_owner_insert"
    on storage.objects for insert
    with check (
        bucket_id = 'postcard-photos'
        and auth.uid()::text = (storage.foldername(name))[1]
    );

drop policy if exists "postcard_photos_owner_delete" on storage.objects;
create policy "postcard_photos_owner_delete"
    on storage.objects for delete
    using (
        bucket_id = 'postcard-photos'
        and auth.uid()::text = (storage.foldername(name))[1]
    );

-- route-files
drop policy if exists "route_files_public_read" on storage.objects;
create policy "route_files_public_read"
    on storage.objects for select
    using (bucket_id = 'route-files');

drop policy if exists "route_files_owner_insert" on storage.objects;
create policy "route_files_owner_insert"
    on storage.objects for insert
    with check (
        bucket_id = 'route-files'
        and auth.uid()::text = (storage.foldername(name))[1]
    );

drop policy if exists "route_files_owner_delete" on storage.objects;
create policy "route_files_owner_delete"
    on storage.objects for delete
    using (
        bucket_id = 'route-files'
        and auth.uid()::text = (storage.foldername(name))[1]
    );

-- =============================================================================
-- Done.
-- =============================================================================
-- 跑完後到 SQL Editor 執行：
--   select count(*) from public.mushrooms;
-- 應該返回 0（空表）。如果報 permission denied 就是 RLS 阻擋你（你還沒登入），
-- 改用 service_role key 或新建一個測試使用者後試 insert。
