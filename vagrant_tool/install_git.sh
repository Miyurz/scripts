#!/bin/bash

sudo apt-get remove git -y
sudo apt-get install vim -y
sudo apt-get install make -y
sudo apt-get install gcc -y
sudo apt-get install libcurl4-gnutls-dev -y
sudo apt-get install libcurl4-openssl-dev -y
sudo apt-get install lib64expat1-dev -y
sudo apt-get install tcl


echo "Install latest git for source available on code.google.com"

rm -rf git-*

wget https://git-core.googlecode.com/files/git-1.9.0.tar.gz
tar xvf git-1.9.0.tar.gz
ls -al
cd git-1.9.0
make
