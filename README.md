# 📦 treef

一個 **高顏值、高效能** 的 CLI 目錄樹狀結構工具，  
專為開發者打造，兼顧美觀、速度與實用性。

支援 emoji、顏色、檔案大小、Git 狀態、時間戳記，  
並針對 macOS / Linux 做效能最佳化，日常開發列目錄再也不拖泥帶水。

---

## 🧩 特色 Features

- 📁 以樹狀結構顯示資料夾與檔案
- ✨ Fancy 模式：emoji + 色彩（預設）
- 📄 Simple 模式：純文字、適合 pipe / log 使用
- 🧵 Git 狀態顯示
    - ✔️ 已追蹤
    - ✏️ 已修改
    - ✨ 未追蹤
- 📦 檔案大小顯示（B / KB / MB / GB）
    - 精簡模式下 **GB 檔案會以紅色標示**
- ⏰ 顯示最後修改時間 (`-t`)
- 📅 顯示建立時間 (`-ct`)
- 📌 可控制遞迴深度 (`-d`)
- 🔍 支援名稱過濾（萬用字元 + 多條件）
- ⚡ 效能優化
    - 單次 `stat` 呼叫
    - Bash 內建字串處理取代 `basename`
    - 不使用暫存檔，改用 Process Substitution
    - Git status 僅在必要時執行

---

## 🚀 安裝方式 Installation

### 使用 Homebrew（建議）

```bash
brew tap mark22013333/treef
brew install treef
```

### 使用 curl（快速）
```bash
curl -L https://raw.githubusercontent.com/mark22013333/treef/main/treef.sh \
  -o /usr/local/bin/treef
chmod +x /usr/local/bin/treef
```

## 🛠️ 使用方式 Usage
```bash
treef [directory] [pattern] [options...]
```
pattern 為 非 flag 的第二個參數起，
若出現多個會自動視為過濾條件。

## 🔧 參數說明 Options
| 參數       | 說明        |
| -------- | --------- |
| `-s`     | 精簡模式      |
| `-h`     | 顯示檔案大小    |
| `-g`     | 顯示 Git 狀態 |
| `-t`     | 顯示最後修改時間  |
| `-ct`    | 顯示建立時間    |
| `-d <n>` | 指定遞迴深度    |
| `-help`  | 顯示說明      |

## 🔍 過濾功能 Filter
```bash
treef . "cheng*"
treef . "cheng*@~testDir"
```

## 🧠 系統相容性
| 平台    | 說明                |
| ----- | ----------------- |
| macOS | BSD stat，完整支援建立時間 |
| Linux | GNU stat，依檔案系統支援  |

## 🧑‍💻 作者 Author
- `Mark Cheng`
- https://github.com/mark22013333

## 📄 授權 License

本專案採用 MIT 授權。歡迎自由使用、修改與散佈。詳見 LICENSE 檔案。