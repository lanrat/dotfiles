#!/usr/bin/env bash
############################
# rm-dead.sh

for file in $(find -L ~/.* -type l);
do
    echo $file
    rm -i $file
done

echo "All Done!"
