#!/usr/bin/env bash

# the dir this script is in
cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
config_backup_dir="~/config_backup"
home="~/"

#helper functions
function link target src {
    if [ -e $src ] && [ ! -L $src ];
    then
        echo "$src exists moving to $config_backup_dir dir"
        mkdir -p $config_backup_dir
        mv $src $config_backup_dir/
    fi
    if [ -L $src ];
    then
        rm $src
    fi
    echo "Creating symlink for $src in home directory."
    ln -s $target $src
}

function downloadSubmodules dir {
    if [ -e $dir/submodules ];
    then
        while read l;
        do
            read -a array <<< $l
            git clone ${array[0]} $dir/${array[1]}
        done < $dir/submodules
    fi
}

#functions for each config
function conky {
    echo "Linking conky"
    link $cwd/conky/conkyrc $home/.conkyrc
    echo "Done!"
}

function git {
    echo "Linking git"
    for file in $(ls $cwd/git);
    do
        link $cwd/git/$file $home/.file
    done
    echo "Done!"
}

function shell {
    echo "Linking shell"
    for file in $(ls $cwd/shell);
    do
        link $cwd/shell/$file $home/.file
    done
    echo "Done!"
}

function tmux {
    echo "Linking tmux"
    link $cwd/tmux/tmux.conf $home/.tmux.conf
    echo "Done!"
}

function xscreensaver {
    echo "Linking xscreensaver"
    link $cwd/xscreensaver/xscreensaver $home/.xscreensaver
    echo "Done!"
}

function vim {
    echo "Linking vim"
    downloadSubmodules $cwd/vim
    link $cwd/vim/vimrc $home/.vimrc
    link $cwd/vim/vim $home/.vim
    echo "Done!"
}

function awesome {
    echo "Linking awesome"
    downloadSubmodules $cwd/vim
    mkdir -p $home/.config
    link $cwd/awesome/awesome $home/.config/awesome
    echo "Done!"
}

function openbox {
    echo "Linking openbox"
    link $cwd/openbox/openbox $home/.config/openbox
    echo "Done!"
}

function terminator {
    echo "Linking terminator"
    link $cwd/terminator/terminator $home/.config/terminator
    echo "Done!"
}

function tint2 {
    echo "Linking tint2"
    link $cwd/tint2/tint2 $home/.config/tint2
    echo "Done!"
}




