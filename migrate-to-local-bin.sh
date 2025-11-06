#!/usr/bin/env bash
# migrate-to-local-bin.sh
# Migrates user binaries from ~/bin to ~/.local/bin

set -eu
set -o pipefail

OLD_BIN="$HOME/bin"
NEW_BIN="$HOME/.local/bin"

echo "=== Migrating from ~/bin to ~/.local/bin ==="
echo

# Create new directory if it doesn't exist
if [ ! -d "$NEW_BIN" ]; then
    echo "Creating $NEW_BIN..."
    mkdir -p "$NEW_BIN"
else
    echo "$NEW_BIN already exists"
fi

# Check if old bin exists and has contents
if [ ! -d "$OLD_BIN" ]; then
    # shellcheck disable=SC2088
    echo "~/bin doesn't exist, nothing to migrate"
    exit 0
fi

# Count files in old bin
file_count=$(find "$OLD_BIN" -mindepth 1 -maxdepth 1 | wc -l)

if [ "$file_count" -eq 0 ]; then
    # shellcheck disable=SC2088
    echo "~/bin is empty, removing directory..."
    rmdir "$OLD_BIN"
    echo "Migration complete!"
    exit 0
fi

echo "Found $file_count items in ~/bin"
echo

# Move each item
find "$OLD_BIN" -mindepth 1 -maxdepth 1 | while read -r item; do
    basename_item=$(basename "$item")
    target="$NEW_BIN/$basename_item"

    if [ -e "$target" ]; then
        echo "WARNING: $target already exists"
        echo "  Old: $item"
        echo "  New: $target"
        read -p "  Overwrite? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "  Skipping $basename_item"
            continue
        fi
        rm -rf "$target"
    fi

    echo "Moving: $basename_item"
    mv "$item" "$target"
done

# Remove old directory if empty
if [ -d "$OLD_BIN" ]; then
    remaining=$(find "$OLD_BIN" -mindepth 1 -maxdepth 1 | wc -l)
    if [ "$remaining" -eq 0 ]; then
        echo
        echo "Removing empty ~/bin directory..."
        rmdir "$OLD_BIN"
    else
        echo
        echo "WARNING: ~/bin still contains $remaining items that were not migrated"
        echo "Please review manually:"
        ls -la "$OLD_BIN"
    fi
fi

echo
echo "=== Migration complete! ==="
echo "All binaries should now be in ~/.local/bin"
echo "Please log out and back in, or run: source ~/.profile"
