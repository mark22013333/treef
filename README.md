# 📦 treef

一個 **高顏值、高效能** 的 CLI 目錄樹狀結構工具。

**treef** 專為開發者打造，採用 **Native Bash 核心重寫**，  
解決傳統腳本在大型專案（如 `node_modules` 或 Java 專案）中  
常見的 **「Too many open files」** 問題，兼顧美觀、速度與實用性。

---

## 🧩 特色 Features

### 🎨 視覺與體驗

- 📁 **樹狀顯示**  
  清晰呈現資料夾與檔案層級結構。

- ✨ **Fancy 模式（預設）**  
  自動為不同類型檔案加上 Emoji 與色彩，資訊一眼可辨。

- 📄 **智慧輸出**  
  當偵測到輸出為檔案（例如 `> file.txt`）時，  
  會自動移除 ANSI 顏色代碼，確保文件乾淨可讀。

- 📦 **智慧大小顯示**  
  檔案大小自動轉換為 B / KB / MB / GB，  
  **GB 級大檔案會以紅色標示**，風險一眼看穿。

---

### 🛠️ 實用功能

- 🧵 **Git 整合**  
  即時顯示檔案狀態：  
  ✔️ 已追蹤 ｜ ✏️ 已修改 ｜ ✨ 未追蹤

- ⏰ **時間資訊**
    - `-t` 顯示最後修改時間
    - `-ct` 顯示建立時間

- 🔍 **強大過濾能力**
    - **包含（Include）**：支援萬用字元（例如 `src*`）
    - **排除（Exclude）**：排除特定目錄（例如 `target`、`node_modules`）
    - **只看目錄**：`-do` 模式，快速檢視整體架構

---

### ⚡ 極致效能（v2.0+）

- 🚀 **Native Bash Globbing**  
  完全移除 `find` 指令依賴，  
  從根本解決 File Descriptor 耗盡問題。

- 🧹 **無暫存檔設計**  
  不產生任何臨時文件，  
  保護 SSD、同時提升執行速度。

- 📉 **單次 `stat` 呼叫**  
  大幅降低系統 I/O 開銷，  
  在大型專案中效能提升非常有感。

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

| 參數          | 說明                              |
|-------------|---------------------------------|
| `-s`        | 精簡模式                            |
| `-h`        | 顯示檔案大小                          |
| `-g`        | 顯示 Git 狀態                       |
| `-t`        | 顯示最後修改時間                        |
| `-ct`       | 顯示建立時間                          |
| `-d <n>`    | 指定遞迴深度                          |
| `-e <list>` | 排除清單：排除指定名稱 (逗號分隔，如 -e bin,obj) |
| `-help`     | 顯示說明                            |

## 💡 使用情境 Examples

### 1️⃣ 日常開發（Dev Mode）

查看專案結構，顯示 Git 狀態與檔案大小，  
同時排除 `node_modules` 與 `dist`：

```bash
treef . -g -h -e node_modules,dist
```

### 2️⃣ 架構檢視（Structure View）

只想看資料夾結構，不想被大量檔案干擾：

```bash
treef -do
```

### 3️⃣ 輸出專案架構文件（Export Architecture）

這是撰寫技術文件時的神器 🚀
過濾特定模組（cheng*）、排除無關的建置檔（target），
限制顯示深度，並輸出成乾淨的純文字架構檔：

```bash
treef . "cheng*" -do -e target,node_modules,.npm-cache -d 15 > Architecture.txt
```

## 🧠 系統相容性

| 平台    | 說明                |
|-------|-------------------|
| macOS | BSD stat，完整支援建立時間 |
| Linux | GNU stat，依檔案系統支援  |

## 🧑‍💻 作者 Author

- `Mark Cheng`
- https://github.com/mark22013333

## 📄 授權 License

本專案採用 MIT 授權。歡迎自由使用、修改與散佈。詳見 LICENSE 檔案。