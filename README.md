# 專案時程共編甘特圖 v7

這個版本支援：

- PM/FAE、SYSTEM、DATA、MODEL 各自填寫 start / end 日期
- 各 Team Lead Time 自動計算
- 任務總 Lead Time 自動用各 Team 日期的最早 start 到最晚 end 計算
- 備註欄位 notes
- 每列新增「結案」勾選欄位，勾選後表格列與甘特圖列會變灰色
- 甘特圖可切換「全部 Team 分色 / 總覽 / 單一 Team」
- Supabase 雲端共編與 Realtime 同步
- 甘特圖移到頁面最上方
- 甘特圖與表格視窗改得更扁，減少頁面整體高度，方便看到表頭
- 表格緊湊版，日期欄寬、列高與整體比例縮小，可一次檢視更多欄位
- 支援新增列、每列新增下方列、清除列資料、刪除列
- 清除列資料會清空負責、日期、備註與結案狀態，但保留項目名稱與階段列設定
- 凍結甘特圖日期標題與左側項目欄
- 凍結表格欄位標題與左側項目欄，橫向/縱向捲動時仍可追蹤列內容

## 升級步驟

本版新增 Supabase 欄位：

```sql
is_closed boolean NOT NULL DEFAULT false
```

如果你已經建立過 Supabase table，請先到 Supabase SQL Editor 執行壓縮檔內的：

```text
supabase_schema_v3.sql
```

或直接執行這段最小升級 SQL：

```sql
ALTER TABLE public.project_tasks
  ADD COLUMN IF NOT EXISTS is_closed boolean NOT NULL DEFAULT false;

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.project_tasks TO anon, authenticated;

NOTIFY pgrst, 'reload schema';
```

執行成功後等 10～30 秒，再用新版 `index.html` 覆蓋舊版網頁，回網頁按 `Ctrl + F5` 強制重新整理。

如果你還沒有執行過 v2 schema，也可以直接執行 `supabase_schema_v3.sql`，它會一起補 Team 日期、notes 與 is_closed 欄位。

## 檔案說明

- `index.html`：主網頁
- `config.js`：Supabase Project URL 與 Publishable key 設定
- `config.example.js`：設定範例
- `supabase_schema.sql`：完整建表與升級 SQL，目前內容同 v3
- `supabase_schema_v2.sql`：Team 日期與備註升級 SQL
- `supabase_schema_v3.sql`：新增結案欄位升級 SQL

## config.js 範例

```js
window.PROJECT_GANTT_CONFIG = {
  SUPABASE_URL: "https://你的-project-id.supabase.co",
  SUPABASE_ANON_KEY: "你的-publishable-key-或-anon-public-key",
  TABLE_NAME: "project_tasks"
};
```

注意：前端只能放 Publishable key / anon public key，不要放 service_role key、secret key 或資料庫密碼。

## 使用方式

1. 勾選該任務由哪個 Team 負責。
2. 在該 Team 的 start / end 欄位填日期。
3. Team LT 與總 Lead Time 會自動計算。
4. 備註欄可填寫進度、風險、卡關原因或確認事項。
5. 勾選「結案」後，該列會變灰色，甘特圖對應列也會變灰。
6. 甘特圖可切換總覽或單一 Team；甘特圖日期標題與左側項目欄會固定。
7. 表格欄位標題與左側項目欄會固定，方便橫向/縱向捲動追蹤。
8. 按上方「新增列」可在最下方新增任務；每列右側「＋下方列」可在該列下方插入任務。
9. 每列右側「清除資料」可清空該列的負責、日期、備註與結案狀態，但保留項目名稱。
10. 每列右側「刪除」可刪除該任務列。

## 注意

如果瀏覽器顯示 `column is_closed does not exist`，代表還沒有執行 `supabase_schema_v3.sql`。
如果瀏覽器顯示 localStorage 模式，代表 `config.js` 沒讀到或 Supabase 設定有問題。
