# 📦 treef

一個美觀、簡潔又實用的 CLI 目錄樹狀結構工具，支援顯示 emoji、顏色、檔案大小、Git 狀態、修改時間等功能，適合日常開發與文件結構瀏覽。

---

## 🧩 特色 Features

* 📁 以樹狀方式顯示資料夾與檔案
* ✨ 支援 fancy 模式：emoji + 色彩
* 🧵 支援 Git 狀態：✔️ 已追蹤、✏️ 已修改、✨ 未追蹤
* 📦 顯示檔案大小（自動轉換 B/KB/MB/GB），在精簡模式下會用紅色標示 GB 檔案
* ⏰ 支援顯示檔案與目錄的最後修改時間 (`-t`)
* 📅 支援顯示檔案與目錄的建立時間 (`-ct`)
* 📌 支援遞迴深度控制 (`-d 2`)
* 📄 支援簡約文字模式 (`-s`)

---

## 🚀 安裝方式 Installation

### ✅ 使用 Homebrew 安裝（建議）

```bash
brew tap mark22013333/treef
brew install treef
```

### ✅ 使用 curl 安裝（快速）

```bash
curl -L https://raw.githubusercontent.com/mark22013333/treef/main/treef.sh -o /usr/local/bin/treef
chmod +x /usr/local/bin/treef
```

---

## 🛠️ 使用方式 Usage

```bash
treef [directory] [options...]
```

### 🔧 可用參數 Options

| 參數           | 功能說明                   |
| ------------ | ---------------------- |
| `-s`         | 精簡模式，不顯示 emoji 與顏色     |
| `-h`         | 顯示檔案大小（human-readable） |
| `-g`         | 顯示 Git 狀態              |
| `-t`         | 顯示最後修改時間             |
| `-ct`        | 顯示建立時間                 |
| `-d <depth>` | 指定遞迴顯示層級深度             |
| `-?`         | 顯示參數說明（本畫面）            |

---

## 📌 使用範例 Examples

```bash
# 列出目前目錄，使用 fancy 模式（預設）
treef

# 列出 home 目錄並顯示 Git 狀態
treef ~/projects -g

# 顯示檔案大小與最後修改時間，並限制深度 2
treef -h -t -d 2

# 以簡潔模式顯示，並加上建立時間
treef /var/log -s -ct
```

---

## 📸 畫面預覽 Screenshot

Fancy 模式搭配時間戳記：

```
📂 my-project/
├── 📁 src ✔️
│   ├── 📄 main.java [Jul 16 10:30] (4KB) ✔️
│   └── 📄 utils.java [Jul 15 18:05] (8KB) ✏️
├── 📄 README.md [Jul 16 09:00] (2KB) ✔️
└── 📄 new-feature.js [Jul 16 11:00] (1KB) ✨
📊 共計：📁 1 資料夾、📄 3 檔案
```

---

## 🧑‍💻 作者 Author

Created by [Mark Cheng](https://github.com/mark22013333)

---

## 📄 授權 License

本專案採用 MIT 授權。歡迎自由使用、修改與散佈。詳見 LICENSE 檔案。