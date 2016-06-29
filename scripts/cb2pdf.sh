#! /usr/bin/env bash

help()
{
    echo "Usage: $0 file.cbz|file.cbr"
}

run()
{
    filename=$(basename "$1")
    extension="${filename##*.}"
    filename="${filename%.*}.pdf"
    
    dir=`mktemp -d`
    if [ "$extension" = "cbr" ]; then
        unrar e "${1}" $dir
    elif [ "$extension" = "cbz" ]; then
        unzip "${1}" -d $dir
    else
        echo "Unsupported Extension: $extension"
        exit
    fi
    
    echo "Creating ${filename}"

    IFS=$'\n'
    convert $(find ${dir} | sort) ${filename}

    rm -rf $dir
}

if [ $# -ne 1 ]; then
    help
else
    if [ -e "$1" ]; then
        run "$1"
    else
        echo "$1 does not exist"
    fi
fi

