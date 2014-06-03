#!/bin/bash

apt-get remove git

echo "Install latest git for source available on code.google.com"

rm -rf git-*

wget https://git-core.googlecode.com/files/git-1.9.0.tar.gz
tar xvf git-1.9.0.tar.gz
ls -al
cd git-1.9.0
make
