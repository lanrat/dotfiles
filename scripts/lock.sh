#!/usr/bin/env sh
TMPBG=$HOME/.screen.png
#TMPBG=/dev/shm/.screen.png

locker()
{
    scrot $TMPBG
    convert $TMPBG -scale 10% -scale 1000% $TMPBG
    i3lock --ignore-empty-password --image $TMPBG
    rm $TMPBG
}

lock()
{
    xautolock -locknow
}

unlock()
{
    xautolock -unlocknow
}

start()
{
    exec xautolock -locker "$0 --locker" \
    -notify 30 -time 15 -notifier "notify-send --urgency critical --expire-time 100000 -- 'LOCKING screen in 30 seconds'"
}

if [ "$1" = "--start" ]; then
    start
elif [ "$1" = "--unlock" ]; then
    unlock
elif [ "$1" = "--locker" ]; then
    locker
elif [ "$#" -ne 0 ]; then
    echo "Usage: $(basename $0) [option]"
    echo "  by defaults locks the screen with xautolock"
    echo "--start   Starts xautolock"
    echo "--unlock  Unlocks xautolock"
    echo "--locker  Run the lock screen without xautolock"
else
    lock
fi