#!/bin/bash

#sample run: ./remove-prefix.sh test t

image=$1
quay_prefix=$2

#remove quay_prefix from image
echo ${image#$quay_prefix}
