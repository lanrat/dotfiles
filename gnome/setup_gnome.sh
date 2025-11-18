#!/usr/bin/env bash
# cspell:words dconf busctl
set -eu
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


function setup_gnome {
    # Check if dconf is available
    if ! command -v dconf &> /dev/null; then
        echo "Error: dconf command not found. Is GNOME installed?"
        exit 1
    fi

    # Validate settings.ini exists and is readable
    if [ ! -f "$SCRIPT_DIR/settings.ini" ]; then
        echo "Error: settings.ini not found at $SCRIPT_DIR/settings.ini"
        exit 1
    fi

    # Run comparison to show what will change
    echo ">> Checking what will change..."
    local skip_settings_import=false
    if [ -x "$SCRIPT_DIR/compare_settings.py" ]; then
        "$SCRIPT_DIR/compare_settings.py"
        local exit_code=$?

        if [ $exit_code -eq 0 ]; then
            # Exit code 0 means no differences
            echo ">> No changes to import, settings already match!"
            skip_settings_import=true
        elif [ $exit_code -eq 2 ]; then
            # Exit code 2 means only system has extra settings (not in settings.ini)
            echo ">> Only system has extra settings not in settings.ini, skipping import"
            skip_settings_import=true
        else
            # Exit code 1 means there are differences to import
            echo ""
            read -p "Do you want to proceed with importing settings? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Import cancelled"
                skip_settings_import=true
            fi
        fi
    else
        echo "Warning: compare_settings.py not found or not executable, skipping comparison check"
    fi

    if [ "$skip_settings_import" = false ]; then
        mkdir -p "$SCRIPT_DIR/backups/"

        # Find most recent backup
        latest_backup=$(find "$SCRIPT_DIR/backups/" -maxdepth 1 -name 'settings_backup_*.ini' -type f -printf '%T+ %p\n' 2>/dev/null | sort -r | head -n1 | cut -d' ' -f2 || true)

        # Only create backup if different from last backup (or no backup exists)
        if [ -z "$latest_backup" ] || ! diff -q <(dconf dump /) "$latest_backup" > /dev/null 2>&1; then
            backup_date="$(date +%Y-%m-%d_%H-%M-%S)"
            backup_filename="settings_backup_$backup_date.ini"
            echo ">> Creating a backup: $backup_filename"
            dconf dump / > "$SCRIPT_DIR/backups/$backup_filename"
        else
            echo ">> No changes detected, skipping backup"
        fi

        echo ">> Importing Settings"
        dconf load / < "$SCRIPT_DIR/settings.ini"
        echo ">> Settings imported successfully!"
    fi

}



# install using GUI extension-manager popup
# this method is not great as it is not blocking and the UUID must be url encoded already
function installGUI() {
    # must be URL encoded
    # this is non-blocking
    UUID="$1"
    xdg-open "gnome-extensions://$UUID?action=install"
}


function installCLI() {
    UUID="$1"

    # Use busctl with a longer timeout (120 seconds) to avoid D-Bus timeout errors
    # The default timeout is too short for downloading extensions
    busctl --user --timeout=120 call \
        org.gnome.Shell.Extensions \
        /org/gnome/Shell/Extensions \
        org.gnome.Shell.Extensions \
        InstallRemoteExtension "s" "$UUID"
}


function compare_extensions() {
    local extensions_file="$SCRIPT_DIR/extensions.txt"

    if [ ! -f "$extensions_file" ]; then
        echo "Error: extensions.txt not found at $extensions_file"
        return 1
    fi

    # Get extensions from file (remove empty lines, comments, and sort)
    local file_extensions
    file_extensions=$(grep -v '^$' "$extensions_file" | grep -v '^#' | sort)

    # Get currently enabled extensions
    local system_extensions
    system_extensions=$(gnome-extensions list --enabled | sort)

    echo "Comparing enabled extensions with extensions.txt..."
    echo ""

    # Show only added/removed lines
    local diff_output
    diff_output=$(diff --color=auto -u <(echo "$system_extensions") <(echo "$file_extensions") | grep -E '^[-+][^-+]' || true)

    if [ -n "$diff_output" ]; then
        echo "Differences found:"
        echo "  - = in extensions.txt but NOT enabled"
        echo "  + = enabled but NOT in extensions.txt"
        echo ""
        echo "$diff_output"
    else
        echo "✓ All extensions match!"
    fi
    echo ""
}


function install_missing_extensions() {
    local extensions_file="$SCRIPT_DIR/extensions.txt"

    if [ ! -f "$extensions_file" ]; then
        echo "Error: extensions.txt not found at $extensions_file"
        return 1
    fi

    # Check if gnome-extensions command is available
    if ! command -v gnome-extensions &> /dev/null; then
        echo "Error: gnome-extensions command not found"
        return 1
    fi

    # Get extensions from file (remove empty lines, comments, and sort)
    local file_extensions
    file_extensions=$(grep -v '^$' "$extensions_file" | grep -v '^#' | sort)

    # Get all installed extensions (enabled or disabled)
    local installed_extensions
    installed_extensions=$(gnome-extensions list --enabled | sort)

    # Find extensions that are not installed
    while IFS= read -r extension; do
        if ! echo "$installed_extensions" | grep -q "^${extension}$"; then
            echo ""
            echo "Extension not installed: $extension"
            read -p "Do you want to install it? (y/N) " -n 1 -r < /dev/tty
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "Installing $extension..."
                installCLI "$extension"
            else
                echo "Skipping $extension"
            fi
        fi
    done <<< "$file_extensions"

    echo ""
    echo "Done checking extensions."
}

# double check that this is really gnome
if [[ "$XDG_CURRENT_DESKTOP" != *"GNOME"* ]]; then
    echo "Gnome not running, detected $XDG_CURRENT_DESKTOP"
    exit
fi

# settings
setup_gnome

# show diff
compare_extensions
# offer to install
install_missing_extensions
