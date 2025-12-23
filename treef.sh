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
SHOW_ONLY_DIRS=false
MAX_DEPTH=99999
file_count=0
dir_count=0
FILTER_INPUT=""
EXCLUDE_INPUT=""

# --- System Settings ---
shopt -s dotglob nullglob
export LC_ALL=C
OS_TYPE=$(uname)

# --- Color Definitions ---
C_RESET=""
C_BLUE=""
C_CYAN=""
C_YELLOW=""
C_RED=""
C_GRAY=""
C_BOLD=""

# --- Functions ---

print_help() {
cat << EOF

📦 treef - 高顏值、高效能 CLI 目錄結構顯示工具
   High-Performance Native Bash Tree Utility

🌲 用法 / Usage:
    treef [directory] [pattern...] [options]

🔧 顯示選項 / Visual Options:
    -s              精簡模式 (無顏色/Emoji) / Simple mode
    -do             只顯示目錄 / Directories only

📊 資訊選項 / Info Options:
    -h              顯示檔案大小 / Show file sizes
    -g              顯示 Git 狀態 / Show Git status
    -t              顯示修改時間 / Show mod time
    -ct             顯示建立時間 / Show creation time

🔍 過濾選項 / Filter Options:
    -d <depth>      遞迴深度 / Recursion depth
    -e <patterns>   排除模式 (逗號分隔) / Exclude patterns (comma-separated)

📝 說明 / Notes:
    * 包含 (Include): 直接輸入名稱作為參數，支援萬用字元 (如 "src*")。
    * 排除 (Exclude): 使用 -e 參數，支援萬用字元 (如 "target,*.log")。

💡 範例 / Examples:
    # 1. 基礎顯示 (Basic)
    treef

    # 2. 深度限制 (Limit Depth) - 僅顯示 2 層目錄
    treef -d 2

    # 3. 架構檢視 (Structure Only) - 只看 cheng 開頭的目錄，不看檔案
    treef . "cheng*" -do

    # 4. 詳細資訊與排除 (Details & Exclude) - 顯示 Git/大小，並排除無關目錄
    treef . -g -h -e target,node_modules,dist

    # 5. 輸出乾淨的文字檔 (Output to File) - 自動移除顏色代碼
    treef . -do > structure.txt

    # 6. 輸出專案架構文件 (Export Project Architecture)
    #    過濾特定模組、排除構建檔與快取、只看目錄結構、指定深度，並存成文字檔
    treef . "cheng*" -do -e target,node_modules,dist,.npm-cache -d 15 > Architecture.txt

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
             size_str="(${C_RED}${human_readable_size}${C_RESET})"
        fi
    fi

    if $SHOW_GIT; then
        git_str=$(get_git_status "$path")
    fi

    local details="$time_str $size_str $git_str"

    if [ "$MODE" == "fancy" ]; then
        if [ -d "$path" ]; then
            printf "%b\n" "${prefix}${connector} 📁 ${C_BLUE}${C_BOLD}$item${C_RESET} $git_str"
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

    local files=("$dir"/*)
    if [ ${#files[@]} -eq 0 ]; then return; fi
    if [ ${#files[@]} -eq 1 ] && [ ! -e "${files[0]}" ] && [ ! -L "${files[0]}" ]; then return; fi

    local entry_count=${#files[@]}

    # --- 1. 排除過濾 (Exclude Logic) ---
    if [ -n "$EXCLUDE_INPUT" ]; then
        local clean_excludes="${EXCLUDE_INPUT//,/ }"
        local non_excluded_files=()

        for item_path in "${files[@]}"; do
            local item_name="${item_path##*/}"
            local should_skip=false

            for exc in $clean_excludes; do
                if [[ "$item_name" == $exc ]]; then
                    should_skip=true
                    break
                fi
            done

            if ! $should_skip; then
                non_excluded_files+=("$item_path")
            fi
        done
        files=("${non_excluded_files[@]}")
        entry_count=${#files[@]}
    fi

    if [ ${#files[@]} -eq 0 ]; then return; fi

    # --- 2. 包含過濾 (Include Logic - 僅限第一層) ---
    if (( depth == 1 )) && [ -n "$FILTER_INPUT" ]; then
        local clean_filters="${FILTER_INPUT//@~/ }"
        local filtered_files=()
        for item_path in "${files[@]}"; do
            local item_name="${item_path##*/}"
            local matched=false
            for pat in $clean_filters; do
                if [[ "$item_name" == $pat ]]; then matched=true; break; fi
            done
            if $matched; then filtered_files+=("$item_path"); fi
        done
        files=("${filtered_files[@]}")
        entry_count=${#files[@]}
    fi

    # --- 3. 目錄過濾 (-do Logic) ---
    if $SHOW_ONLY_DIRS; then
        local dir_only_files=()
        for item_path in "${files[@]}"; do
            if [ -d "$item_path" ]; then dir_only_files+=("$item_path"); fi
        done
        files=("${dir_only_files[@]}")
        entry_count=${#files[@]}
    fi

    # --- 4. 繪製 ---
    local i=0
    for item_path in "${files[@]}"; do
        ((i++))
        local item_name="${item_path##*/}"
        if [[ "$item_name" == "." || "$item_name" == ".." ]]; then continue; fi
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
            print_tree "$item_path" "$prefix$new_prefix" "$((depth + 1))"
        else
            if ! $SHOW_ONLY_DIRS; then
                ((file_count++))
                format_line "$prefix" "$connector" "$item_name" "$item_path"
            fi
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
        -do) SHOW_ONLY_DIRS=true; shift ;;
        -e) EXCLUDE_INPUT="$2"; shift 2 ;;
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

if [ "$MODE" == "fancy" ] && [ -t 1 ]; then
    C_RESET="\033[0m"
    C_BLUE="\033[1;34m"
    C_CYAN="\033[1;36m"
    C_YELLOW="\033[0;33m"
    C_RED="\033[0;31m"
    C_GRAY="\033[0;90m"
    C_BOLD="\033[1m"
fi

if [ "$MODE" == "fancy" ]; then
    printf "%b\n" "📂 ${C_CYAN}${C_BOLD}$(basename "$directory")${C_RESET}/"
else
    echo "$(basename "$directory")/"
fi

if [ "$MODE" == "fancy" ]; then
    if [ -n "$FILTER_INPUT" ]; then
        printf "%b\n" "${C_GRAY}(🔍 Filter: ${FILTER_INPUT//@~/, })${C_RESET}"
    fi
    if [ -n "$EXCLUDE_INPUT" ]; then
        printf "%b\n" "${C_GRAY}(🚫 Exclude: $EXCLUDE_INPUT)${C_RESET}"
    fi
fi

print_tree "$directory" "" 1

echo ""
if [ "$MODE" == "fancy" ]; then
    if $SHOW_ONLY_DIRS; then
        printf "%b\n" "📊 共計：📁 ${C_BLUE}${C_BOLD}$dir_count${C_RESET} 資料夾"
    else
        printf "%b\n" "📊 共計：📁 ${C_BLUE}${C_BOLD}$dir_count${C_RESET} 資料夾、📄 ${C_YELLOW}$file_count${C_RESET} 檔案"
    fi
else
    if $SHOW_ONLY_DIRS; then
         echo "共計：$dir_count 資料夾"
    else
         echo "共計：$dir_count 資料夾, $file_count 檔案"
    fi
fi