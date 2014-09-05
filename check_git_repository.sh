#!/bin/sh

#Toggle between debug mode
#set -x

check_if_bare=$(git rev-parse --is-bare-repository)
echo ${check_if_bare}

[ "${check_if_bare}" == "true" ]  &&  echo "Bare repository" || echo "Non bare repository"

case ${check_if_bare} in
	true) echo "Bare repo related things"
	      echo "Branches available"
	      git branch -r
	;;

        false) echo "Non bare related things"
	       echo "Branches available"
	       git branch -r
	;;

        *) echo "Bullshit stuff" ;;

esac

