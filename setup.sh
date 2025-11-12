#!/usr/bin/env bash
set -eu
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

#
# helper functions
#

function run {
    c="${1%/}"
    if [ "$c" == "nvim" ]; then
        c="vim"
    fi
    c="link_$c"
    eval "$c"
}

function link_all {
    echo "Linking all configs"
    for dir in "$SCRIPT_DIR"/*/
    do
        dir=${dir%*/}
        dir=${dir##*/}
        if [ "$dir" != "~" ];
        then
            run $dir
        fi
    done
}

function make_link {
    target="$1"
    src="$2"

    if [ -L "$src" ];
    then
        rm "$src"
    fi
    if [ -e "$src" ];
    then
        echo "$src already exists, making backup $src.bak"
        mv "$src" "$src.bak"
    fi
    parent_dir=$(dirname "$src")
    mkdir -p "$parent_dir"
    echo "Creating symlink for $src --> $target"
    ln -sf "$target" "$src"
}

function get_submodule {
    REPO="$1"
    FOLDER="$2"

    if [ ! -e "$FOLDER" ];
    then
        echo "Cloning $REPO to $FOLDER"
        git clone --depth 1 "$REPO" "$FOLDER"
    else
        echo "Updating git repo in $FOLDER"
        git --git-dir="$FOLDER/.git" pull
    fi
}

#
# config functions
#

function link_code-server {
    make_link "$SCRIPT_DIR/code-server" "$HOME/.config/code-server"
}

function link_vim {
    VUNDLE_URL="https://github.com/gmarik/Vundle.vim.git"
    VUNDLE_DIR="$SCRIPT_DIR/vim/vim/bundle/Vundle.vim"

    if [ ! -e "$VUNDLE_DIR" ];
    then
        echo "Downloading Vundle"
        get_submodule "$VUNDLE_URL" "$VUNDLE_DIR"
    fi

    echo "Linking vim"
    make_link "$SCRIPT_DIR/vim/vimrc" "$HOME/.vimrc"
    make_link "$SCRIPT_DIR/vim/vim" "$HOME/.vim"
    make_link "$SCRIPT_DIR/nvim" "$HOME/.config/nvim"

    echo "Downloading plugins"
    vim +PluginInstall +qall
}


function link_git {
    echo "Linking git"
    for file in "$SCRIPT_DIR"/git/*;
    do
        bname=$(basename "$file")
        make_link "$SCRIPT_DIR/git/$bname" "$HOME/.$bname"
    done
}

function link_psql {
    echo "Linking psql"
    for file in "$SCRIPT_DIR"/psql/*;
    do
        bname=$(basename "$file")
        make_link "$file" "$HOME/.$bname"
    done
}

function link_shell {
    echo "Linking shell"
    for file in "$SCRIPT_DIR"/shell/*;
    do
        bname=$(basename "$file")
        make_link "$SCRIPT_DIR/shell/$bname" "$HOME/.$bname"
    done
}

function link_tmux {
    echo "Linking tmux"
    make_link "$SCRIPT_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
}

function link_sqlite {
    echo "Linking sqlite"
    make_link "$SCRIPT_DIR/sqlite/sqliterc" "$HOME/.sqliterc"
}

function link_docker-plugins {
    echo "Linking Docker"
    make_link "$SCRIPT_DIR/docker-plugins" "$HOME/.docker/cli-plugins"
}

function link_scripts {
    echo "Linking scripts"
    for script in "$SCRIPT_DIR"/scripts/*
    do
        bname=$(basename "$script")
        name="${bname%.*}"
        make_link "$script" "$HOME/.local/bin/$name"
    done
}

function link_ssh {
    echo "Linking SSH TODO"
    # TODO
}

function link_gnome {
    echo "Updating Gnome Settings"

    mkdir -p "$SCRIPT_DIR/gnome/backups/"

    # Find most recent backup
    latest_backup=$(ls -t "$SCRIPT_DIR/gnome/backups/settings_backup_"*.ini 2>/dev/null | head -n1)

    # Only create backup if different from last backup (or no backup exists)
    if [ -z "$latest_backup" ] || ! diff -q <(dconf dump /) "$latest_backup" > /dev/null 2>&1; then
        backup_date="$(date +%Y-%m-%d_%H-%M-%S)"
        backup_filename="settings_backup_$backup_date.ini"
        echo ">> Creating a backup: $backup_filename"
        dconf dump / > "$SCRIPT_DIR/gnome/backups/$backup_filename"
    else
        echo ">> No changes detected, skipping backup"
    fi

    echo ">> Importing Settings"
    dconf load / < "$SCRIPT_DIR/gnome/settings.ini"
}

function link_iterm2 {
    echo "Linking iterm2"
    "$SCRIPT_DIR/iterm2/iterm2.sh"
}

function link_appimage {
    local pattern="$1"
    local desktop_file="$2"

    # shellcheck disable=SC2206
    appimage=( $HOME/.local/bin/$pattern )
    if [ -f "${appimage[0]}" ]; then
        echo ">> found: appimage: ${appimage[0]}"
        make_link "$SCRIPT_DIR/apps/$desktop_file" "$HOME/.local/share/applications/$desktop_file"
    fi
}

function link_apps {
    echo "Linking apps"
    if [ "$(uname)" != "Linux" ]; then
        echo "Apps only supported on Linux"
        exit 1
    fi
    for app in "$SCRIPT_DIR"/apps/*.desktop
    do
        bname=$(basename "$app")
        # only copy if app is installed or if named *-app.desktop
        if [[ "$bname" == *-app.desktop ]]; then
            echo "STATIC APP: $bname"
            make_link "$app" "$HOME/.local/share/applications/$bname"
        elif [ -f "/usr/share/applications/$bname" ]; then
            echo ">> $bname installed"
            make_link "$app" "$HOME/.local/share/applications/$bname"
        else
            echo "app $bname not found, skipping..."
        fi
    done


    ## AppImage files in ~/.local/bin
    link_appimage "OrcaSlicer*.AppImage" "orcaslicer.desktop"
    link_appimage "FreeCAD*.AppImage" "freecad.desktop"

    update-desktop-database "$HOME/.local/share/applications/"
}

function link_claude {
    echo "Linking Claude Code"
    make_link "$SCRIPT_DIR/claude/settings.json" "$HOME/.claude/settings.json"
    make_link "$SCRIPT_DIR/claude/ccstatusline/settings.json" "$HOME/.ccstatusline/settings.json"
}

function link_environment.d {
    echo "Linking environment.d"
    for file in "$SCRIPT_DIR"/environment.d/*
    do
        bname=$(basename "$file")
        echo "linking env: $file"
        make_link "$file" "$HOME/.config/environment.d/$bname"
    done
    echo "> You need to log out and back it to have the new environment take effect."
}

function link_dev {
    run git
    run vim
    run shell
    run scripts
    run tmux
    run psql
    run sqlite
}

function link_server {
    link_dev
    run claude
    run code-server
    run docker-plugins
    run ssh
}


function link_mac {
    link_dev
    run iterm2
}

function link_linux_desktop {
    link_server
    run apps
    run environment.d

    # if dconf for gnome is present, restore gnome settings
    if command -v "dconf" &> /dev/null; then
        run gnome
    fi
}

args=("$@")

function auto {
    # test if running in codespaces
    if [ "${CODESPACES-}" = true ] ; then
        echo 'Enabling codespaces mode'
        args+=(dev)
    fi

    # If running over ssh, assume server
    if [[ -n "${SSH_CONNECTION:-}" ]] || [[ -n "${SSH_CLIENT:-}" ]]; then
        echo 'SSH detected: Enabling server mode'
        args+=(server)
    fi

    # Running in a desktop session (value will be "wayland" or "x11")
    if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]] || [[ "${XDG_SESSION_TYPE:-}" == "x11" ]]; then
        echo "${XDG_SESSION_TYPE:-} detected: Enabling desktop mode"
        args+=(linux_desktop)
    fi

    # Running on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo 'macOS detected: Enabling Mac mode'
        args+=(mac)
    fi
}

if [ "${#args[@]}" -eq 0 ];
then
    echo "No arguments provided, running in auto mode"
    auto
fi

# run all links
for arg in "${args[@]}"
do
    run "$arg"
done

# Ensure dotfiles have secure permissions (not group-writable)
echo "Fixing dotfile permissions..."
find "$SCRIPT_DIR" -type f -exec chmod g-w {} +
echo "Done!"

