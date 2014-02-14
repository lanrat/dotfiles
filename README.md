dotfiles
========

A place to store my configuration files.

USAGE: Run `./link.sh <module to link>`

All
--------

Configures all 


Vim
--------

Automagically configures vim with the following plugins:

https://github.com/tpope/vim-pathogen.git vim/bundle/vim-pathogen

https://github.com/scrooloose/nerdtree.git vim/bundle/nerdtree

https://github.com/Townk/vim-autoclose.git vim/bundle/autoclose

https://github.com/Lokaltog/vim-powerline.git vim/bundle/vim-powerline

https://github.com/tpope/vim-fugitive.git vim/bundle/vim-fugitive

https://github.com/majutsushi/tagbar.git vim/bundle/tagbar

https://github.com/msanders/snipmate.vim.git vim/bundle/snipmate

https://github.com/nanotech/jellybeans.vim.git vim/bundle/jellybeans

TODO for OSX:
    Download, compile, and install MacVim if it's not already installed!


Shell
--------

Configures the bash shell.

Replaces the ~/.bashrc and ~/.bash_profile with the profiles here.

Changes for all unix systems:
   1. A fancy prompt
   2. Some aliases
   3. bash_profile updates the path, and sources bashrc
   4. Adds functions that make your life easier:
        1. extract $1 #Extract things. No more remember ugly tar crap!
        2. scour $1 #Where the hell is it? 

Changes for OSX:
    Shell colors (yay!)
    vi opens the edit script. Link the scripts if you want this.


Scripts
--------

Links commonly used scripts to ~/bin/

Scripts linked for all unix systems:

Scripts linked for OSX:
    edit    -   Just opens MacVim


Terminator
--------


Conky
--------
