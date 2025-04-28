#!/bin/bash
#
LOG=scratch
DIR=src

if [ -f $LOG ]; then
    rm $LOG
fi

if [ ! -d $DIR ]; then
    echo "Executing from the wrong directory!  $DIR not found."
    exit
fi

touch $LOG
find src -type f \( -name "*.html" -o -name "*.java" -o -name "*.properties" \) -print0 | xargs -0 -I {} sh -c 'echo -e "\n--- {} ---" && cat "{}"' >> $LOG

ls -l $LOG
