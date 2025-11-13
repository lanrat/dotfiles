#!/usr/bin/env bash
set -eu
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )



# install using GUI extension-manager popup
# this method is not great as it is not blocking and the UUID must be url encoded already
function installGUI() {
    # must be URL encoded
    # this is non-blocking
    $UUID="$1"
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
    local file_extensions=$(grep -v '^$' "$extensions_file" | grep -v '^#' | sort)

    # Get currently enabled extensions
    local system_extensions=$(gnome-extensions list --enabled | sort)

    echo "Comparing enabled extensions with extensions.txt..."
    echo ""

    # Show only added/removed lines
    local diff_output=$(diff --color=auto -u <(echo "$system_extensions") <(echo "$file_extensions") | grep -E '^[-+][^-+]' || true)

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
    local file_extensions=$(grep -v '^$' "$extensions_file" | grep -v '^#' | sort)

    # Get all installed extensions (enabled or disabled)
    local installed_extensions=$(gnome-extensions list --enabled | sort)

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


# show diff
compare_extensions

# offer to install
install_missing_extensions