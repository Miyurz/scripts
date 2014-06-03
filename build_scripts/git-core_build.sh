#!/bin/bash

source common.sh git 

get_details

echo I am in $(pwd)

echo Checking the installed git version.
git --version

echo Compiling git source code ...
make prefix=/usr

echo Installing the built git version ...
#make install

echo Compiling git Documentation ...
make dist-doc

echo Checking built Documentation... 
GIT_DOC_TARBALL=$(basename $(find . -iname git-manpages*.tar.gz ) 2>/dev/null )

echo Installing git manual pages for the newly built git ...
#tar -xzvf ${GIT_DOC_TARBALL} -C /usr/local/share/man

echo Checking the built git version ...
./git --version


