#!/bin/bash


function call_git_config {

  echo Git config variable : $1
  echo Value passed : $2

  [ -z "$1" -o -z "$2" ] && { echo "Exiting ..."; exit 1; } || { echo Going ahead; }

  [ "$2" == "Skip" -o "$2" == "S" -o "$2" == "skip" -o "$2" == "s" ]  && { echo User wants to skip;  return 0;} || { echo User desnt want to skip; }

  echo "Proceeding now.."

  git config --global $1 $2 2>> $0.log
}

echo You may skip any of the questions by keying "S","s","Skip","skip"

echo Enter your name
read name

call_git_config user.name $name


echo Enter your email address
read email
call_git_config user.email $email

echo Enter your choice of editor
read editor
call_git_config core.editor $editor

echo Enter your choice of diff tool
read difftool
call_git_config merge.tool $difftool

echo Your git config settings look like:
git config --list
