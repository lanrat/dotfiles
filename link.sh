#!/usr/bin/env bash
############################
# link.sh

########## Variables
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # the dir this script is in
old=old
olddir=$dir/$old             # old dotfiles backup directory
me=$(basename $0)
##########

# move any existing dotfiles in homedir to dotfiles_old directory, then create symlinks 
for file in $(ls $dir);
do
    if [[ ($file != $old) && ($file != $me) ]];
    then
        if [ -e ~/.$file ];
        then
            echo "$file exists moving to $old dir"
            mv ~/.$file $olddir
        fi

        echo "Creating symlink to $file in home directory."
        ln -s $dir/$file ~/.$file
    fi
done

echo "All Done!"
