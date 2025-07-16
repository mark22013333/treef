#!/bin/bash

# --- Configuration ---
MODE="fancy"
SHOW_SIZE=false
SHOW_GIT=false
SHOW_MOD_TIME=false
SHOW_CREATION_TIME=false
MAX_DEPTH=99999
file_count=0
dir_count=0

# --- Cleanup Handler ---
# Create a temporary file for directory listings.
# Set up a trap to automatically delete the temp file when the script exits.
TMPFILE=$(mktemp 2>/dev/null || mktemp -t 'treef')
trap 'rm -f "$TMPFILE"' EXIT


# --- Functions ---

print_help() {
cat << EOF

📦 treef - 高顏值 CLI 目錄結構顯示工具

🌲 用法 / Usage:
    treef [directory] [options...]

🔧 可用參數 / Options:
    -s              精簡模式 Simple mode (no emoji/color)
    -h              顯示檔案大小 Show file sizes
    -g              顯示 Git 狀態 Show Git file status
    -t              顯示最後修改時間 Show last modification time
    -ct             顯示建立時間 Show creation time
    -d <depth>      指定遞迴深度 Set recursion depth
    -?              顯示本說明 Show this help

📌 範例:
    treef -h -t
    treef ~/projects -d 2 -g
    treef /etc -s -ct

EOF
exit 0
}

human_size() {
    local size=$1
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
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo ""
        return
    fi

    local rel_path
    rel_path=$(realpath --relative-to="$(git rev-parse --show-toplevel)" "$path" 2>/dev/null)
    rel_path=${rel_path:-$path}
    local status
    status=$(git status --porcelain -- "$rel_path" 2>/dev/null)

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

    # --- Robust Time Fetching Logic ---
    if $SHOW_MOD_TIME; then
        local mod_time
        # Try macOS/BSD stat first, then fall back to GNU date for Linux
        if ! mod_time=$(stat -f "%Sm" -t "%b %d %H:%M" "$path" 2>/dev/null); then
            mod_time=$(date -r "$path" "+%b %d %H:%M" 2>/dev/null)
        fi
        time_str="[$mod_time]"
    fi

    if $SHOW_CREATION_TIME; then
        local creation_time
        # Try macOS/BSD stat for creation time first
        if ! creation_time=$(stat -f "%SB" -t "%b %d %H:%M" "$path" 2>/dev/null); then
            # Fall back to Linux stat for creation time
            local creation_epoch
            creation_epoch=$(stat -c %W "$path" 2>/dev/null)
            if [ -n "$creation_epoch" ]; then
                creation_time=$(date -d "@$creation_epoch" "+%b %d %H:%M" 2>/dev/null)
            fi
        fi
        time_str="$time_str[$creation_time]"
    fi

    # --- Size and Git Status ---
    if $SHOW_SIZE && [ -f "$path" ]; then
        local size
        size=$(stat -c %s "$path" 2>/dev/null || stat -f %z "$path")
        local human_readable_size
        human_readable_size=$(human_size "$size")
        size_str="($human_readable_size)"

        if [[ "$human_readable_size" == *GB* && "$MODE" == "simple" ]]; then
            size_str="(\033[0;31m${human_readable_size}\033[0m)"
        fi
    fi

    if $SHOW_GIT; then
        git_str=$(get_git_status "$path")
    fi

    # --- Final Output Formatting ---
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

    find "$dir" -mindepth 1 -maxdepth 1 -print0 | LC_ALL=C sort -z > "$TMPFILE"

    local entries=()
    while IFS= read -r -d '' entry; do
        entries+=("$entry")
    done < "$TMPFILE"

    local entry_count=${#entries[@]}
    local i=0

    for item_path in "${entries[@]}"; do
        ((i++))
        local item_name
        item_name=$(basename "$item_path")

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
        -\?) print_help ;;
        *) directory="${directory:-$1}"; shift ;;
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

print_tree "$directory" "" 1

echo ""
if [ "$MODE" == "fancy" ]; then
    printf "%b\n" "📊 共計：📁 \033[1;34m$dir_count\033[0m 資料夾、📄 \033[0;33m$file_count\033[0m 檔案"
else
    echo "共計：$dir_count 資料夾, $file_count 檔案"
fi
