# LociiGhost Community

Pikmin Bloom 飛人社群分享平台 —— 菇點、明信片、路線共享。
跟 [LociiGhost macOS app](https://github.com/YCH81/LociiGhost) 共用同一個後端。

## 這個 repo 是什麼

兩件事：

1. **Supabase 後端 schema**（`supabase/`）
   - Postgres 表：菇點 / 明信片 / 路線 / 個人檔案
   - Row-Level Security 規則（公開讀、登入寫、改自己的）
   - Storage buckets（照片、GPX 檔）

2. **公開瀏覽用的網頁**（`web/`，W3 才會建）
   - 靜態 Astro 站，host on GitHub Pages
   - 不需要 macOS app 也能看
   - 每個項目都有「在 LociiGhost 中打開」按鈕（URL scheme `lociighost://...`）

LociiGhost macOS app 內的右側面板 UI 跟上傳邏輯**不在這個 repo**，
那部分屬於 macOS app 本身，放在 [YCH81/LociiGhost](https://github.com/YCH81/LociiGhost)。

## 架構

```
                ┌────────────────────┐
                │     Supabase       │  $0/mo
                │  Postgres + Storage │  (until ~10k MAU)
                │  + Auth (Apple SSO) │
                └─────────┬──────────┘
                          │
              ┌───────────┴────────────┐
              │                         │
        macOS LociiGhost          web (Astro static)
        Sign in with Apple        Sign in with Apple
        Swift + supabase-swift    JS + supabase-js
        上傳 / 下載 + teleport     瀏覽 + 上傳
                                  「在 app 中打開」連結
                                  （lociighost:// URL scheme）
```

## 規則

| 動作 | 誰能做 |
|------|--------|
| 瀏覽所有菇點 / 明信片 / 路線 | 所有人（不用登入） |
| 上傳 | 登入後（Apple Sign-In） |
| 修改 / 刪除 | 只能改自己上傳的 |
| 看別人的個人檔案 | 公開（只看 display name + 上傳統計） |

## 部署狀態

| 元件 | 狀態 | 路徑 |
|------|------|------|
| Supabase schema | 等使用者執行 `supabase/schema.sql` | `supabase/` |
| GitHub Pages 網頁 | **W3.1 已上線**（4 頁 placeholder，等 Supabase 接通顯示真資料） | `web/` |
| GitHub Actions 部署 pipeline | **已設定** — `main` 上 `web/**` 一改就自動 redeploy | `.github/workflows/deploy.yml` |
| macOS app 右側面板 | 未開工（W2） | 主 repo |

網頁 deploy URL：https://ych81.github.io/LociiGhost-Community/

## 一次性：啟用 GitHub Pages + 設定環境變數

第一次部署前要做：

1. **啟用 Pages**：repo 頁面 → Settings → Pages → **Source** 改成 `GitHub Actions`（不是 `Deploy from a branch`）
2. **設定 Supabase 連線**（W1 跑完後）：repo 頁面 → Settings → Secrets and variables → Actions → **Variables** tab → New repository variable：
   - `PUBLIC_SUPABASE_URL` = 你 Supabase 專案的 URL
   - `PUBLIC_SUPABASE_ANON_KEY` = anon public key

   **注意是 Variables 不是 Secrets** —— anon key 本來就會嵌進前端 bundle，公開沒關係；RLS 才是真的安全層。

設完後到 Actions tab 手動跑一次 `Deploy web to GitHub Pages` workflow（或 push 任何 web/ 下的檔案）。

## 本地開發

```bash
cd web
npm install
npm run dev           # → http://localhost:4321/LociiGhost-Community/
```

建 `.env.local` 從 `.env.example` 複製，填入你的 Supabase 連線。沒填也能跑，所有頁面會顯示「後端尚未連接」的 placeholder。

## 設定 Supabase（W1 你要做的事）

詳見 [`supabase/setup.md`](supabase/setup.md)。
30 分鐘搞定，免費。
