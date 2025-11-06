#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RM_FLAG=false
BROKEN_COUNT=0
BAK_COUNT=0

# Parse arguments
if [[ "$1" == "--rm" ]]; then
    RM_FLAG=true
fi

find_broken_symlinks() {
    local search_dir="$1"
    shift
    while read -r link; do
        target=$(readlink -f "$link" || readlink "$link")
        # Check if resolved target starts with $DIR
        if [[ "$target" == "$DIR"* ]]; then
            echo "$link"
            if [[ "$RM_FLAG" == true ]]; then
                rm "$link"
            else
                BROKEN_COUNT=$((BROKEN_COUNT + 1))
            fi
        fi
    done < <(find "$search_dir" "$@" -xtype l 2>/dev/null)
}

find "$DIR" -xtype l | while read -r link; do
    echo "$link"
    if [[ "$RM_FLAG" == true ]]; then
        rm "$link"
    fi
done

find_broken_symlinks "$HOME/.config/"
find_broken_symlinks "$HOME/.local/"
find_broken_symlinks "$HOME" -maxdepth 2

# Find .bak files created by setup.sh
echo ""
echo "Checking for leftover .bak files from setup.sh..."
find "$HOME/.config/" "$HOME/.local/" "$HOME" -maxdepth 2 -name "*.bak" 2>/dev/null | while read -r bakfile; do
    echo "$bakfile"
    if [[ "$RM_FLAG" == true ]]; then
        rm "$bakfile"
    else
        BAK_COUNT=$((BAK_COUNT + 1))
    fi
done

# Display message if broken links were found and --rm flag was not used
if [[ "$BROKEN_COUNT" -gt 0 ]] && [[ "$RM_FLAG" == false ]]; then
    echo ""
    echo "Found $BROKEN_COUNT broken symlink(s) pointing to $DIR"
    echo "Run with --rm flag to remove them: $0 --rm"
fi

# Display message if .bak files were found and --rm flag was not used
if [[ "$BAK_COUNT" -gt 0 ]] && [[ "$RM_FLAG" == false ]]; then
    echo ""
    echo "Found $BAK_COUNT .bak file(s) from setup.sh"
    echo "Run with --rm flag to remove them: $0 --rm"
fi
