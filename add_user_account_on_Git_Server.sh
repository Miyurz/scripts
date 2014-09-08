#!/bin/bash

authors_file_list=$1
echo $authors_file_list

#[ [ -n "$authors_file_list" ] && [ -f "$authors_file_list" ] || echo "variable not set"; ]  && { echo $?; echo "file  there"; } || { echo $?;  echo "file not there"; exit 1; }  

while read -r line
do
    echo $line
    name=` echo ${line//[[:blank:]]/} | sed  's/[*<[A-Za-z0-9.@]*>//' `
    name=` echo "$name" | sed 's/=//g' `
    echo User to be added is $name

    useradd $name
    passwd $name
    usermod -G Git_Users $name
done < "$authors_file_list"
