# Supabase Setup（30 分鐘搞定）

第一次設定。跑完一次後 schema 之後改 SQL 重跑就好（schema.sql 是 idempotent）。

---

## 1. 開 Supabase 專案 (~5 分鐘)

1. 到 [supabase.com](https://supabase.com) 用 GitHub 帳號登入
2. **New project**
   - Organization：建議新開一個叫 `YCH81-personal`
   - Project name：`lociighost-community`
   - Region：**Tokyo (ap-northeast-1)** —— 飛人多在台日，這個延遲最低
   - Database password：**用密碼產生器產一個強密碼，存到 1Password / Bitwarden**。事後不會再用到，但弄丟就只能重 reset
3. 等 2 分鐘 build 好

完成後到 **Settings → API** 抄下：
- **Project URL**（`https://xxxxx.supabase.co`）
- **anon public key**（給前端用，會 expose 沒關係）
- **service_role secret**（**絕對不要外洩**，這個是後門）

把這三個存進你的 1Password / 筆記，後續 W2 / W3 都要用。

---

## 2. 跑 schema.sql (~2 分鐘)

1. Supabase Dashboard → **SQL Editor** → New query
2. 把 [`schema.sql`](schema.sql) 整份貼上
3. 按 **Run**

預期看到：`Success. No rows returned`。

驗證：
- 左邊 **Table Editor** 應該看到 4 張表：`profiles`、`mushrooms`、`postcards`、`routes`
- **Storage** 應該看到 2 個 buckets：`postcard-photos`、`route-files`
- **Authentication → Policies** 應該看到每張表 3-4 條 policy

---

## 3. 開啟 Apple Sign-In (~10 分鐘)

### Apple Developer Console
1. 到 [developer.apple.com/account](https://developer.apple.com/account) 用你的 Apple ID（`frankie.y.che@gmail.com`，Team ID `M6269VDRCZ`）登入
2. **Certificates, IDs & Profiles → Identifiers** → 點 `+` 新增
   - 選 **Services IDs**（不是 App IDs）
   - Description: `LociiGhost Community Sign In`
   - Identifier: `com.lociighost.community.signin`（這個是 Apple 給 OAuth client ID 用的，跟主 app bundle id 區分）
3. 新增完成後點進去 edit → 勾 **Sign In with Apple** → 設定：
   - Primary App ID: 選 `com.lociighost.app`（你 macOS app 的 bundle id）
   - Domains and Subdomains: `xxxxx.supabase.co`（你的 Supabase URL 主機名，不含 https://）
   - Return URLs: `https://xxxxx.supabase.co/auth/v1/callback`
4. **Keys** → `+` 新增 key
   - Key Name: `LociiGhost Community Sign In Key`
   - 勾 **Sign In with Apple** → Configure → 選同個 Primary App ID
   - 下載 `.p8` 檔（**只能下載一次，弄丟要重發**）
   - 記下 **Key ID**（10 個字母數字）

### Supabase Dashboard
1. **Authentication → Providers → Apple** → Enable
2. 填：
   - Services ID: `com.lociighost.community.signin`
   - Team ID: `M6269VDRCZ`
   - Key ID: 剛剛抄的
   - Secret Key (.p8 file content): 用文字編輯器打開剛下載的 `.p8`，整份貼上（含 `-----BEGIN PRIVATE KEY-----` 跟 `-----END PRIVATE KEY-----` 兩行）
3. **Save**

---

## 4. 開 Email Magic Link 當備案 auth (~1 分鐘)

不是每個飛人都用 Apple ID。Email magic link 當備案。

1. **Authentication → Providers → Email** → Enable
2. 預設設定就好
3. **Email Templates** 之後 W3 階段再客製成繁中

---

## 5. 自己手動測一筆資料 (~5 分鐘)

驗證整套是不是會動：

1. **Authentication → Users** → `Invite a user`：填你自己 email（不用是 Apple ID）
2. 收信點 magic link，登入 Supabase Studio Mock（沒有 UI 但 auth.users 會多一筆）
3. **SQL Editor** 跑：
   ```sql
   -- 取得你剛建的測試 user 的 uid
   select id, email from auth.users order by created_at desc limit 1;
   ```
4. 複製那個 uid，再跑一筆假插入：
   ```sql
   -- 把下面的 uid 換成上面查到的
   insert into public.mushrooms
       (mushroom_type, name, description, lat, lng, uploader_id, uploader_name)
   values
       ('red', '台北 101 紅菇', 'test', 25.0339, 121.5645,
        '<paste-your-uid-here>'::uuid, '飛人測試');
   ```
   應該成功。
5. 不帶 auth 再跑一次 select：
   ```sql
   select id, name, mushroom_type from public.mushrooms;
   ```
   應該看到你剛插的那筆（公開可讀）。

驗證完把測試資料刪掉：
```sql
delete from public.mushrooms where name = '台北 101 紅菇';
```

---

## 你完成這 5 步驟後

告訴我，下面 W2 / W3 開始接手：

| 階段 | 工作 | 你的角色 |
|------|------|----------|
| W2 | macOS app 右側 panel + Supabase Swift SDK 整合 | 等我做完試用 |
| W3 | 公開瀏覽用的 Astro 網頁 | 等我做完試用 |

需要你提供的東西（只有兩個）：
- **Project URL**
- **anon public key**

（service_role secret **絕對不要給我看**，只有 server-side 任務才用得到，這個 repo / 主 repo 都不需要）

---

## Schema 改了之後

`schema.sql` 是 idempotent 的（policy 是 drop+create，index 是 if not exists，bucket 是 upsert）。
未來改了 schema 就：

1. 改 `schema.sql`
2. SQL Editor 整份再貼一次跑
3. Commit + push

不需要任何 migration tool，scale 還小可以這樣搞。
之後資料多了再考慮上 `supabase db diff` workflow。
