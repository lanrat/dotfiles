#! /usr/bin/env bash

help()
{
    echo "Usage: $0 file.cbz"
}

run()
{
    dir=`mktemp -d`
    unzip "$1" -d $dir

    filename=$(basename "$1")
    filename="${filename%.*}.pdf"

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

