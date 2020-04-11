#!/usr/bin/env bash

# the dir this script is in
cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#
# helper functions
#

function run {
    c="${1%/}"
    if [ $c == "sublime-text-3" ];
    then
        c="sublime3"
    fi
    c="link_$c"
    eval ${c}
}

function link_all {
    echo "Linking all configs"
    for dir in $cwd/*/
    do
        dir=${dir%*/}
        dir=${dir##*/}
        if [ "$dir" != "~" ];
        then
            run ${dir}
        fi
    done
}

function make_link {
    target=$1
    src=$2

    if [ -L "${src}" ];
    then
        rm "${src}"
    fi
    if [ -e "${src}" ];
    then
        echo "${src} already exists, makeing backup ${src}.bak"
        mv "${src}" "${src}.bak"
    fi
    parent_dir=$(dirname "${src}")
    mkdir -p "${parent_dir}"
    echo "Creating symlink for ${src}"
    ln -sf "${target}" "${src}"
}

function get_submodule {
    REPO=$1
    FOLDER=$2

    if [ ! -e $FOLDER ];
    then
        echo "Cloning $REPO to $FOLDER"
        git clone --depth 1 $REPO $FOLDER
    else
        echo "Updating git repo in $FOLDER"
        git --git-dir=$FOLDER/.git pull
    fi

}

#
# config functions
#

function link_vim {
    VUNDLE_URL="https://github.com/gmarik/Vundle.vim.git"
    VUNDLE_DIR="$cwd/vim/vim/bundle/Vundle.vim"

    if [ ! -e $VUNDLE_DIR ];
    then
        echo "Downloading Vundle"
        get_submodule $VUNDLE_URL $VUNDLE_DIR
    fi

    echo "Linking vim"
    make_link $cwd/vim/vimrc ~/.vimrc
    make_link $cwd/vim/vim ~/.vim
    make_link $cwd/nvim ~/.config/nvim

    echo "Downloading plugins"
    vim +PluginInstall +qall
}


function link_git {
    echo "Linking git"
    for file in $(ls $cwd/git);
    do
        make_link $cwd/git/$file ~/.$file
    done
}

function link_psql {
    echo "Linking psql"
    for file in $(ls $cwd/psql);
    do
        make_link $cwd/psql/$file ~/.$file
    done
}

function link_shell {
    echo "Linking shell"
    for file in $(ls $cwd/shell);
    do
        make_link $cwd/shell/$file ~/.$file
    done
}

function link_tmux {
    echo "Linking tmux"
    make_link $cwd/tmux/tmux.conf ~/.tmux.conf
}

function link_awesome {
    echo "Linking awesome"
    make_link $cwd/awesome ~/.config/awesome
    make_link $cwd/awesome/libinput-gestures.conf  ~/.config/libinput-gestures.conf
}

function link_compton {
    echo "Linking compton"
    make_link $cwd/compton/compton.conf ~/.config/compton.conf
}

function link_skippy-xd {
    echo "Linking skippy-xd"
    make_link $cwd/skippy-xd ~/.config/skippy-xd
}

function link_sqlite {
    echo "Linking sqlite"
    make_link $cwd/sqlite/sqliterc ~/.sqliterc
}



function link_sublime3 {
    echo "Linking Sublime Text"
    BASE=~/.config/sublime-text-3
    if [ "$(uname)" = "Darwin" ]; then
        echo -e "\t Detected OSX"
        ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" /usr/local/bin/subl
        BASE="${HOME}/Library/Application Support/Sublime Text 3"
    fi
    make_link "${cwd}/sublime-text-3/User" "${BASE}/Packages/User"
}

function link_atom {
    echo "Linking atom"
    make_link "${cwd}/atom/config.cson" ~/.atom/config.cson
    apm install --packages-file ${cwd}/atom/package.list
    # backup with: apm list --installed --bare > atom/package.list
}

function link_scripts {
    echo "Linking scripts"
    for script in $cwd/scripts/*
    do
        bname=$(basename "$script")
        name="${bname%.*}"
        make_link $script ~/bin/$name
    done
    #wget --no-verbose --output-document ~/bin/rsub https://raw.githubusercontent.com/aurora/rmate/master/rmate
    #chmod +x ~/bin/rsub
    #wget --no-verbose --output-document ~/bin/speedtest-cli https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
    #chmod +x ~/bin/speedtest-cli
}

if [ "$#" -eq 0 ];
then
    echo "Usage: $0 {all | CONFIG_TO_LINK}"
    exit 1
fi

run ${1}
