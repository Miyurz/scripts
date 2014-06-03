#!/bin/bash

function install_package {

  apt-get install ${package} -y &> log

  if [ $? == 0 ];
  then
    echo ${package} installed via apt-get successfully.
  else
    echo ${package} did not install right.
    exit 1;
  fi

}

apt-get update

echo "Install necessary editors for developers"
install_package vim

echo "Download source of development libaries and install them"

declare -a packages=('make' \
                     'gcc' \ 
                     'libcurl4-gnutls-dev' \
                     'libcurl4-openssl-dev' \
                     'gcc-multilib' \
                     'lib64expat1-dev');


for package in "${packages[@]}" 
do
   echo Software package to be installed : ${package}
   install_package ${package}
done


