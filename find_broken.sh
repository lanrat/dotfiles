#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RM_FLAG=false

# Parse arguments
if [[ "$1" == "--rm" ]]; then
    RM_FLAG=true
fi

find_broken_symlinks() {
    local search_dir="$1"
    shift
    find "$search_dir" "$@" -xtype l | while read -r link; do
        target=$(readlink -f "$link" || readlink "$link")
        # Check if resolved target starts with $DIR
        if [[ "$target" == "$DIR"* ]]; then
            echo "$link"
            if [[ "$RM_FLAG" == true ]]; then
                rm "$link"
            fi
        fi
    done
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

