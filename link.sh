#!/usr/bin/env bash

# the dir this script is in
cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#helper functions
function link {
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

function downloadSubmodules {
    dir=$1
    if [ -e $dir/submodules ];
    then
        while read l;
        do
            if [ -n "$l" ];
            then
                read -a array <<< $l
                if [ ! -e $dir/${array[1]} ];
                then
                    git clone ${array[0]} $dir/${array[1]}
                else
                    echo "Updating git repo ${array[1]}"
                    git --git-dir=$dir/${array[1]}/.git pull
                fi
            fi
        done < $dir/submodules
    fi
}


#config functions
function vim {
    echo "Linking vim"
    downloadSubmodules $cwd/vim
    link $cwd/vim/vimrc ~/.vimrc
    link $cwd/vim/vim ~/.vim
}

function conky {
    echo "Linking conky"
    link $cwd/conky/conkyrc ~/.conkyrc
}

#can not be called git, conflicts with download submodules
function git_config {
    echo "Linking git"
    for file in $(ls $cwd/git);
    do
        link $cwd/git/$file ~/.$file
    done
}

function shell {
    echo "Linking shell"
    for file in $(ls $cwd/shell);
    do
        link $cwd/shell/$file ~/.$file
    done
}

function tmux {
    echo "Linking tmux"
    link $cwd/tmux/tmux.conf ~/.tmux.conf
}

function xscreensaver {
    echo "Linking xscreensaver"
    link $cwd/xscreensaver/xscreensaver ~/.xscreensaver
}

function awesome {
    echo "Linking awesome"
    downloadSubmodules $cwd/awesome
    link $cwd/awesome/awesome ~/.config/awesome
}

function openbox {
    echo "Linking openbox"
    link $cwd/openbox/openbox ~/.config/openbox
}

function terminator {
    echo "Linking terminator"
    link $cwd/terminator/terminator ~/.config/terminator
}

function tint2 {
    echo "Linking tint2"
    link $cwd/tint2/tint2 ~/.config/tint2
}

function sublime {
    echo "Linking Sublime Text"
    link $cwd/sublime-text-3/User ~/.config/sublime-text-3/Packages/User
    echo "Downloading Package Manager PLugin"
    wget -P ~/.config/sublime-text-3/Installed\ Packages/ https://sublime.wbond.net/Package%20Control.sublime-package
}

function scripts {
    echo "Linking scripts"
    for script in $cwd/scripts/*
    do
        link $script ~/bin/$(basename $script)
    done
}

function run {
    if [ $1 == "git" ];
    then
        c="git_config"
    elif [ $1 == "sublime-text-3" ];
    then
        c="sublime"
    else
        c=$1
    fi
    eval ${c}
}

function all {
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

if [ "$#" -eq 0 ];
then
    echo "Usage: $0 {all | CONFIG_TO_LINK}"
    exit
fi

run ${1}
