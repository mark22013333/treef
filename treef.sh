#!/bin/bash

# --- Configuration ---
MODE="fancy"
SHOW_SIZE=false
SHOW_GIT=false
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
    -d <depth>      指定遞迴深度 Set recursion depth
    -?              顯示本說明 Show this help

📌 範例:
    treef -h
    treef ~/projects -d 2 -g
    treef /etc -s

EOF
exit 0
}

human_size() {
    local size=$1
    if [ "$size" -lt 1024 ]; then
        echo "${size}B"
    elif [ "$size" -lt 1048576 ]; then
        echo "$((size / 1024))KB"
    else
        echo "$((size / 1048576))MB"
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

    if $SHOW_SIZE && [ -f "$path" ]; then
        local size
        size=$(stat -c %s "$path" 2>/dev/null || stat -f %z "$path")
        size_str="($(human_size "$size"))"
    fi

    if $SHOW_GIT; then
        git_str=$(get_git_status "$path")
    fi

    if [ "$MODE" == "fancy" ]; then
        if [ -d "$path" ]; then
            echo -e "${prefix}${connector} 📁 \033[1;34m$item\033[0m $git_str"
        else
            echo -e "${prefix}${connector} 📄 $item $size_str $git_str"
        fi
    else
        echo "${prefix}${connector} $item $size_str $git_str"
    fi
}

print_tree() {
    local dir="$1"
    local prefix="$2"
    local depth="$3"

    if (( depth > MAX_DEPTH )); then return; fi

    # Use a temporary file for maximum portability, avoiding subshell issues.
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
        -d) MAX_DEPTH="$2"; shift 2 ;;
        "-?") print_help ;;
        *) directory="${directory:-$1}"; shift ;;
    esac
done

directory="${directory:-.}"

if [ ! -d "$directory" ]; then
    echo "❌ 目錄不存在：$directory"
    exit 1
fi

if [ "$MODE" == "fancy" ]; then
    echo -e "📂 \033[1;36m$(basename "$directory")\033[0m/"
else
    echo "$(basename "$directory")/"
fi

print_tree "$directory" "" 1

echo ""
if [ "$MODE" == "fancy" ]; then
    echo -e "📊 共計：📁 \033[1;34m$dir_count\033[0m 資料夾、📄 \033[0;33m$file_count\033[0m 檔案"
else
    echo "共計：$dir_count 資料夾, $file_count 檔案"
fi
