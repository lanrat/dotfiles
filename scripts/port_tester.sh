#!/usr/bin/env bash

NB_CONNECTION=10
PORT_START=1
PORT_END=65535

# TODO parallel, currently could take up to 18 hours...
# 40 threads would be ~ 27 min
# takes 1:11m when no network connection w/ single thread
for (( i=$PORT_START; i<=$PORT_END; i=i+NB_CONNECTION ))
do
    iEnd=$((i + NB_CONNECTION))
    for (( j=$i; j<$iEnd; j++ ))
    do
        #(curl --connect-timeout 1 "portquiz.net:$j" &> /dev/null && echo "> $j") &
        >&2 echo "testing $j"
        (nc -w 1 -z portquiz.net "$j" &> /dev/null && echo "> $j") &
    done
    wait
done