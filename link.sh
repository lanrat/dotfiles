#!/usr/bin/env bash
############################
# link.sh

########## Variables
cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # the dir this script is in
old=old
olddir=$cwd/$old             # old dotfiles backup directory
me=$(basename $0)
home_config=home
##########

# move any existing dotfiles in homedir to old directory, then create symlinks 
for file in $(ls $cwd/$home_config);
do
    if [ -e ~/.$file ] && [ ! -L ~/.$file ];
    then
        echo "$file exists moving to $old dir"
        mv ~/.$file $olddir/$file
    fi
    if [ -L ~/.$file ];
    then
        rm ~/.$file
    fi
    echo "Creating symlink to $file in home directory."
    ln -s $cwd/$home_config/$file ~/.$file
done

#create .config file if it does not exist
if [ ! -e ~/.config ];
then
    echo "Creating config dir"
    mkdir -p ~/.config
fi

# same as above but with the .config directory
for file in $(ls $cwd/config);
do
    if [ -e ~/.config/$file ] && [ ! -L ~/.config/$file ];
    then
        echo "config/$file exists moving to $old/config dir"
        mv ~/.config/$file $olddir/config/$file
    fi
    if [ -L ~/.config/$file ];
    then
        rm ~/.config/$file
    fi
    echo "Creating symlink to config/$file in home directory."
    ln -s $cwd/config/$file ~/.config/$file
done


echo "All Done!"
