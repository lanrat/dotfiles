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
    if [ "$c" == "sublime-text-3" ]; then
        c="sublime3"
    elif [ "$c" == "nvim" ]; then
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
        echo "$src already exists, makeing backup $src.bak"
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

function link_sublime3 {
    echo "Linking Sublime Text"
    BASE="$HOME/.config/sublime-text-3"
    if [ "$(uname)" = "Darwin" ]; then
        echo -e "\t Detected OSX"
        ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" /usr/local/bin/subl
        BASE="$HOME/Library/Application Support/Sublime Text 3"
    fi
    make_link "$SCRIPT_DIR/sublime-text-3/User" "$BASE/Packages/User"
}

function link_scripts {
    echo "Linking scripts"
    for script in "$SCRIPT_DIR"/scripts/*
    do
        bname=$(basename "$script")
        name="${bname%.*}"
        make_link "$script" "$HOME/bin/$name"
    done
}

function link_ssh {
    echo "Linking SSH TODO"
    # TODO
}

function link_iterm2 {
    echo "Linking iterm2"
    "$SCRIPT_DIR/iterm2/iterm2.sh"
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
        # only copy if app is installed
        if [ -f "/usr/share/applications/$bname" ]; then
            echo ">> $bname installed"
            make_link "$app" "$HOME/.local/share/applications/$bname"
        else
            echo "app $bname not found, skipping..."
        fi
    done
    update-desktop-database "$HOME/.local/share/applications/"
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

args=("$@")

# test if running in codespaces
if [ "${CODESPACES-}" = true ] ; then
    echo 'Enabling codespaces mode'
    args+=(dev)
fi


if [ "${#args[@]}" -eq 0 ];
then
    echo "Usage: $0 {all | CONFIG_TO_LINK}"
    exit 1
fi

# run all links
for arg in "$args"
do
    run "$arg"
done

