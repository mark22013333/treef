#!/bin/bash

# ==============================================================================
# 📦 treef - 高顏值、高效能 CLI 目錄結構顯示工具 (Native Bash Version)
# ==============================================================================

# --- Configuration ---
MODE="fancy"
SHOW_SIZE=false
SHOW_GIT=false
SHOW_MOD_TIME=false
SHOW_CREATION_TIME=false
MAX_DEPTH=99999
file_count=0
dir_count=0
FILTER_INPUT=""

# --- System Settings ---
# 開啟 glob 設定，讓 * 可以抓到隱藏檔，並不匹配空字串
shopt -s dotglob nullglob
# 設定語言環境以確保排序一致
export LC_ALL=C

# 偵測系統
OS_TYPE=$(uname)

# --- Functions ---

print_help() {
cat << EOF

📦 treef - 高顏值 CLI 目錄結構顯示工具 (Native Fix)

🌲 用法 / Usage:
    treef [directory] [pattern] [options...]

🔧 可用參數 / Options:
    -s              精簡模式 Simple mode (no emoji/color)
    -h              顯示檔案大小 Show file sizes
    -g              顯示 Git 狀態 Show Git file status
    -t              顯示最後修改時間 Show last modification time
    -ct             顯示建立時間 Show creation time
    -d <depth>      指定遞迴深度 Set recursion depth
    -help           顯示本說明 Show this help

🔍 過濾功能 / Filter:
    支援萬用字元 (*) 以及使用 '@~' 分隔多個條件。
    範例: treef . "cheng*"

EOF
exit 0
}

human_size() {
    local size=$1
    if [ -z "$size" ] || [ "$size" -eq 0 ]; then
        echo "0B"
        return
    fi
    if [ "$size" -lt 1024 ]; then
        echo "${size}B"
    elif [ "$size" -lt 1048576 ]; then
        echo "$((size / 1024))KB"
    elif [ "$size" -lt 1073741824 ]; then
        echo "$((size / 1048576))MB"
    else
        echo "$((size / 1073741824))GB"
    fi
}

get_git_status() {
    local path="$1"
    [ ! -e "$path" ] && return

    # 這裡的 git status 呼叫無法避免，但在大型專案若不需 git 建議不加 -g
    local status
    status=$(git status --porcelain --ignore-submodules=dirty -- "$path" 2>/dev/null)

    if [[ -z "$status" ]]; then
        echo "✔️"
    elif [[ "$status" =~ ^\ M ]]; then
        echo "✏️"
    elif [[ "$status" =~ ^\?\? ]]; then
        echo "✨"
    else
        echo "✖️"
    fi
}

format_line() {
    local prefix="$1"
    local connector="$2"
    local item="$3"
    local path="$4"
    local size_str=""
    local git_str=""
    local time_str=""

    local f_size=0
    local f_mtime=0
    local f_ctime=0

    if $SHOW_SIZE || $SHOW_MOD_TIME || $SHOW_CREATION_TIME; then
        if [ "$OS_TYPE" == "Darwin" ]; then
            read -r f_size f_mtime f_ctime <<< $(stat -f "%z %m %B" "$path" 2>/dev/null)
        else
            read -r f_size f_mtime f_ctime <<< $(stat -c "%s %Y %W" "$path" 2>/dev/null)
        fi
        f_size=${f_size:-0}
        f_mtime=${f_mtime:-0}
        f_ctime=${f_ctime:-0}
    fi

    if $SHOW_MOD_TIME && [ "$f_mtime" -gt 0 ]; then
        local mod_time
        if [ "$OS_TYPE" == "Darwin" ]; then
             mod_time=$(date -r "$f_mtime" "+%b %d %H:%M")
        else
             mod_time=$(date -d "@$f_mtime" "+%b %d %H:%M")
        fi
        time_str="[$mod_time]"
    fi

    if $SHOW_CREATION_TIME && [ "$f_ctime" -gt 0 ]; then
        local creation_time
        if [ "$OS_TYPE" == "Darwin" ]; then
             creation_time=$(date -r "$f_ctime" "+%b %d %H:%M")
        else
             creation_time=$(date -d "@$f_ctime" "+%b %d %H:%M")
        fi
        time_str="$time_str[$creation_time]"
    fi

    if $SHOW_SIZE && [ -f "$path" ]; then
        local human_readable_size
        human_readable_size=$(human_size "$f_size")
        size_str="($human_readable_size)"
        if [[ "$human_readable_size" == *GB* && "$MODE" == "simple" ]]; then
            size_str="(\033[0;31m${human_readable_size}\033[0m)"
        fi
    fi

    if $SHOW_GIT; then
        git_str=$(get_git_status "$path")
    fi

    local details="$time_str $size_str $git_str"

    if [ "$MODE" == "fancy" ]; then
        if [ -d "$path" ]; then
            printf "%b\n" "${prefix}${connector} 📁 \033[1;34m$item\033[0m $git_str"
        else
            printf "%b\n" "${prefix}${connector} 📄 $item $details"
        fi
    else
        echo "${prefix}${connector} $item $details"
    fi
}

print_tree() {
    local dir="$1"
    local prefix="$2"
    local depth="$3"

    if (( depth > MAX_DEPTH )); then return; fi

    # ---------------------------------------------------------
    # 核心修復：使用原生 Bash Globbing 取代 find
    # ---------------------------------------------------------

    # 讀取目錄下所有檔案到陣列 (已由 LC_ALL=C 自動排序)
    # shopt -s dotglob 確保能抓到隱藏檔
    local files=("$dir"/*)

    # 檢查是否為空目錄
    if [ ${#files[@]} -eq 0 ]; then return; fi
    # 有時 nullglob 沒生效，若陣列只有一個且不存在，則視為空
    if [ ${#files[@]} -eq 1 ] && [ ! -e "${files[0]}" ] && [ ! -L "${files[0]}" ]; then return; fi

    local entry_count=${#files[@]}

    # 如果有過濾條件且在第一層，我们需要先計算真正符合條件的數量，以便繪製正確的樹狀線 (└──)
    if (( depth == 1 )) && [ -n "$FILTER_INPUT" ]; then
        local clean_filters="${FILTER_INPUT//@~/ }"
        local filtered_files=()

        for item_path in "${files[@]}"; do
            local item_name="${item_path##*/}"
            local matched=false

            # 手動模擬 find 的 OR 邏輯
            for pat in $clean_filters; do
                # 使用 Bash [[ == ]] 進行 wildcard 比對
                if [[ "$item_name" == $pat ]]; then
                    matched=true
                    break
                fi
            done

            if $matched; then
                filtered_files+=("$item_path")
            fi
        done

        # 替換成過濾後的列表
        files=("${filtered_files[@]}")
        entry_count=${#files[@]}
    fi

    local i=0
    for item_path in "${files[@]}"; do
        ((i++))
        local item_name="${item_path##*/}"

        # 排除 . 和 .. (雖然 glob 通常不會抓到，但保險起見)
        if [[ "$item_name" == "." || "$item_name" == ".." ]]; then continue; fi

        # 排除 .git 目錄，避免掃描過慢
        if [[ "$item_name" == ".git" ]]; then continue; fi

        local connector="├──"
        local new_prefix="│   "
        if (( i == entry_count )); then
            connector="└──"
            new_prefix="    "
        fi

        if [ -d "$item_path" ]; then
            ((dir_count++))
            format_line "$prefix" "$connector" "$item_name" "$item_path"
            # 遞迴
            print_tree "$item_path" "$prefix$new_prefix" "$((depth + 1))"
        else
            ((file_count++))
            format_line "$prefix" "$connector" "$item_name" "$item_path"
        fi
    done
}

# --- Main Execution ---

directory=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s) MODE="simple"; shift ;;
        -h) SHOW_SIZE=true; shift ;;
        -g) SHOW_GIT=true; shift ;;
        -t) SHOW_MOD_TIME=true; shift ;;
        -ct) SHOW_CREATION_TIME=true; shift ;;
        -d) MAX_DEPTH="$2"; shift 2 ;;
        -help) print_help ;;
        *)
            if [ -z "$directory" ]; then directory="$1"; else
                [ -n "$FILTER_INPUT" ] && FILTER_INPUT="${FILTER_INPUT}@~${1}" || FILTER_INPUT="$1"
            fi
            shift
            ;;
    esac
done

directory="${directory:-.}"

if [ ! -d "$directory" ]; then
    echo "❌ 目錄不存在：$directory"
    exit 1
fi

if [ "$MODE" == "fancy" ]; then
    printf "%b\n" "📂 \033[1;36m$(basename "$directory")\033[0m/"
else
    echo "$(basename "$directory")/"
fi

[ -n "$FILTER_INPUT" ] && [ "$MODE" == "fancy" ] && echo -e "\033[0;90m(🔍 Filter: ${FILTER_INPUT//@~/, })\033[0m"

print_tree "$directory" "" 1

echo ""
if [ "$MODE" == "fancy" ]; then
    printf "%b\n" "📊 共計：📁 \033[1;34m$dir_count\033[0m 資料夾、📄 \033[0;33m$file_count\033[0m 檔案"
else
    echo "共計：$dir_count 資料夾, $file_count 檔案"
fi