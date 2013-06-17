#!/usr/bin/env bash
############################
# link.sh

########## Variables
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # the dir this script is in
old=old
olddir=$dir/$old             # old dotfiles backup directory
me=$(basename $0)
##########

# move any existing dotfiles in homedir to old directory, then create symlinks 
for file in $(ls $dir);
do
    if [[ ($file != $old) && ($file != $me) && ($file != "config") ]];
    then
        if [ -e ~/.$file ] && [ ! -L ~/.$file ];
        then
            echo "$file exists moving to $old dir"
            mv ~/.$file $olddir/$file
        fi
        if [ ! -L ~/.$file ];
        then
            echo "Creating symlink to $file in home directory."
            ln -s $dir/$file ~/.$file
        fi
    fi
done

#create .config file if it does not exist
if [ ! -e ~/.config ];
then
    echo "Creating config dir"
    mkdir -p ~/.config
fi

# same as above but with the .config directory
for file in $(ls $dir/config);
do
    if [ -e ~/.config/$file ] && [ ! -L ~/.config/$file ];
    then
        echo "config/$file exists moving to $old/config dir"
        mv ~/.config/$file $olddir/config/$file
    fi
    if [ ! -L ~/.config/$file ];
    then
        echo "Creating symlink to config/$file in home directory."
        ln -s $dir/config/$file ~/.config/$file
    fi
done


echo "All Done!"
