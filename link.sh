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
    if [ -L $src ];
    then
        rm $src
    fi
    mkdir -p `dirname $src`
    echo "Creating symlink for $src"
    ln -sf $target $src
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
    
    echo "Downloading plugins"
    vim +PluginInstall +qall
}

function link_conky {
    echo "Linking conky"
    make_link $cwd/conky/conkyrc ~/.conkyrc
}

function link_git {
    echo "Linking git"
    for file in $(ls $cwd/git);
    do
        make_link $cwd/git/$file ~/.$file
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

function link_xscreensaver {
    echo "Linking xscreensaver"
    make_link $cwd/xscreensaver/xscreensaver ~/.xscreensaver
    make_link $cwd/xscreensaver/Xresourcess ~/.Xresourcess
}

function link_awesome {
    echo "Linking awesome"
    get_submodule https://github.com/bioe007/awesome-revelation.git $cwd/awesome/modules/revelation
    get_submodule https://github.com/lanrat/awesome-freedesktop.git $cwd/awesome/modules/awesome-freedesktop
    make_link $cwd/awesome ~/.config/awesome
}

function link_openbox {
    echo "Linking openbox"
    make_link $cwd/openbox/openbox ~/.config/openbox
}

function link_terminator {
    echo "Linking terminator"
    make_link $cwd/terminator/terminator ~/.config/terminator
}

function link_tint2 {
    echo "Linking tint2"
    make_link $cwd/tint2/tint2 ~/.config/tint2
}

function link_sublime3 {
    echo "Linking Sublime Text"
    SUBL_Pacakge_DIR=~/.config/sublime-text-3/Installed\ Packages/
    SUBL_Package_Control_URL="https://sublime.wbond.net/Package%20Control.sublime-package"
    make_link $cwd/sublime-text-3/User ~/.config/sublime-text-3/Packages/User
    if [ ! -e "$SUBL_Pacakge_DIR/Package Control.sublime-package" ]
    then
        echo "Downloading Package Manager Plugin"
        wget -P "$SUBL_Pacakge_DIR" "$SUBL_Package_Control_URL"
    fi
}

function link_scripts {
    echo "Linking scripts"
    for script in $cwd/scripts/*
    do
        make_link $script ~/bin/$(basename $script)
    done
}

function link_ssh {
    echo "Linking ssh"
    SSH_CONFIG=~/Dropbox/config/ssh
    if [ -e "$SSH_CONFIG" ];
    then
        make_link $SSH_CONFIG ~/.ssh/config
    else
        echo "$SSH_CONFIG does not exist!"
    fi
}


if [ "$#" -eq 0 ];
then
    echo "Usage: $0 {all | CONFIG_TO_LINK}"
    exit 1
fi

run ${1}
