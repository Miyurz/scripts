#!/bin/bash

ls -1 ~/Release_tool 2> count.txt | wc -l > count.txt

var=$(cut -d, -f1 count.txt)

echo "No of files is $var"

if [[ "$var" -gt 3 ]]
  then
    printf "Found new documents...\n"
  else
    printf "No new documents found.\n"
  fi
