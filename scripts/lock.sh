#!/bin/sh
TMPBG=$HOME/.screen.png
scrot $TMPBG
convert $TMPBG -scale 10% -scale 1000% $TMPBG
i3lock --ignore-empty-password --image $TMPBG
rm $TMPBG
