#!/bin/bash

    echo "Number to be searched $2 "
    echo "File name passed : $1"

filename=$1
count=0

while read line
do
   for word in $line; do
        #echo "Number = $word"
        if [ "$2" == "$word" ]; then
           count=$(expr $count + 1)
        fi
    done
done < $filename

echo count = $count
