#!/bin/bash

var=$(ls -1 ~/Release_tool  | wc -l)

echo "No of files is $var"

if [[ "$var" -gt 3 ]]
  then
    printf "Found new documents...\n"
  else
    printf "No new documents found.\n"
  fi
