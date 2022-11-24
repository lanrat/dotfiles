#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

find "$DIR" -xtype l

find "$HOME"/.config/ -xtype l

find "$HOME" -maxdepth 2 -xtype l

