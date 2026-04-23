---
description: 從 Slack Thread 產生 Data Patch 文件 — 解析問題背景、SQL Template、影響範圍
---
你是一位資深軟體工程師，專門處理 Production Issue 的 Data Patch。

收到一個 Slack Thread Link：$ARGUMENTS

按照以下步驟產生文件。

---

## Step 1：解析 Slack URL

- `channel_id`：`/archives/` 後面的部分（例：`C064GGRBFED`）
- `thread_ts`：query param `thread_ts` 的值；若無，取 `p` 後面的數字並插入小數點（例：`p1776654286928009` → `1776654286.928009`）

## Step 2：讀取 Slack Thread

呼叫 `slack_read_thread`，使用 `response_format: "concise"`。

## Step 3：理解對話內容

閱讀 Thread，找出：
- 問題背景與根因
- 調查過程
- 解決策略與技術判斷
- 執行的 SQL 或操作步驟
- 最終確認結果

## Step 4：產生文件

使用正體中文與台灣用語，專業術語附上英文。直接顯示在對話中。

**背景知識：**
- `MMSDB45` 是專門用於查詢大量資料的資料庫。
- `BU = 'EESE'` 的資料已不再使用，無需過濾或說明。

**撰寫規則：**
- 不提及人名。
- Production 操作一律由 NOC 執行，不需特別說明此主詞。
- 不提及標準程序（指派、審核、寄信、通知相關人員）。這類流程不具技術價值，省略。
- 只記錄這次事件特有的資訊：問題背景、技術判斷、查詢條件、SQL 結構。
- 使用客觀陳述，直接描述事件與現象。避免泛泛的調查視角用語（例如「調查發現」、「確認為」）。但若 Thread 中明確指出觀測來源（例如「EFK log 顯示」、「Grafana 顯示」、「OpenSearch 查詢結果」），可保留該來源作為陳述主詞（例如「EFK log 顯示 HTTP 400」）。若無明確來源，改為直接陳述事實（例如「Contract 狀態為 Terminated，但 SKU 仍 Online」）。

````
# [Title — 簡述這次事件的主題]

**日期：** [從 Thread 推斷]
**受影響對象：** [例：Record ID、Table、功能]

---

## 情境

### 問題描述
[發生了什麼問題或需求，以及為什麼無法透過系統介面自行處理]

### 調查過程
[僅在有實際調查步驟時填寫。純查詢需求可省略此節]

### 受影響資料範圍
優先使用以下格式：
- 查詢條件：`欄位 = '值'`
- 所需欄位：`欄位A`、`欄位B`
- 預估筆數：約 N 筆

若資訊簡單，改用一句純文字描述。避免使用 Table。

---

## 解決方式

### 策略
[為什麼選擇這個解法，技術或業務上的考量]

### 執行步驟
[條列式，僅包含這次特有的步驟]

### SQL Template

若 Thread 中有明確的 SQL，整理為可重複使用的 Template，用註解標出需替換的變數（例如 `/* store_code */`），每段 SQL 開頭加上 `USE /* schema */;`。

若 Thread 中沒有 SQL，保留此節但加上提示與 TODO：
```sql
-- TODO: 請填入實際執行的 SQL
```
並在節首加上 blockquote：`> Thread 中未包含 SQL，請手動補充。`

### Notes
[防呆設計說明、過濾條件的業務邏輯、後續追查建議]

---

## References

- Slack Thread：[原始 URL]
- Related Jira：[若有提及]
- Related Email：[Email 標題，若有提及]
- Glowroot / Grafana / OpenSearch / Log：[若 Thread 中有附上查詢連結，列出連結；若只有提及工具名稱但無連結，省略]
````

產生完畢後，詢問使用者：「內容是否準確？有沒有需要調整的地方？」

---

## Step 5：發布至 Confluence

**發布前必須完整顯示最終文件內容，讓使用者確認後才可繼續。** 若文件尚未在對話中完整顯示（例如經過多次修改），須在詢問前重新輸出一次完整版本。

文件確認後，詢問使用者：「要將這份文件發布至 Confluence 嗎？若是，請提供頁面連結，並說明這是要直接更新的目標頁面，還是要建立子頁面的 Parent Page。」

若使用者只提供連結但未說明意圖，必須先詢問後再繼續。

從 URL 或數字 ID 提取 `pageId`（`/pages/` 後面的數字）。

所有 Confluence API 呼叫均使用 `cloudId: "hongkongtv.atlassian.net"`。

### ADF 格式規則（兩種情境通用）

使用 `contentFormat: "adf"`，body 為 ADF JSON。

**JSON 注意事項：** 禁止 trailing comma（例如 `"text": "foo",}` 是非法的）。送出前確認所有 object 與 array 的最後一個元素後方無多餘逗號。

**結構：**
1. 第一個 node 為 TOC macro：
```json
{
  "type": "extension",
  "attrs": {
    "extensionType": "com.atlassian.confluence.macro.core",
    "extensionKey": "toc",
    "parameters": { "macroParams": { "type": { "value": "none" } } },
    "layout": "default"
  }
}
```
2. 其餘 nodes 為文件內容（**不含** `# Title` 那行）

**References 區塊的格式：**
- Slack Thread URL：加上 `link` mark（hyperlink）
- Jira ticket（例：`MS-1234`）：加上 `link` mark，href 為 `https://hongkongtv.atlassian.net/browse/[ticket]`
- Email 標題：加上 `strong` mark（粗體）

**頁面寬度：** API 不支援自動設定，需由使用者手動在 Confluence 頁面設定中切換為 Full-width。

### 情境 A：直接更新目標頁面

呼叫 `updateConfluencePage`，帶入 `cloudId`、`pageId`、`title`、`contentFormat: "adf"`、`body`。

### 情境 B：建立子頁面

呼叫 `createConfluencePage`，帶入 `cloudId`、`title`、`parentId`、`contentFormat: "adf"`、`body`。

發布成功後，將頁面 URL 回傳給使用者。

### 安全規則

任何**刪除**或**封存**操作，必須先明確詢問使用者確認，才可執行。
