#!/bin/bash

echo -e "\n****************************************"
echo Backing up Git production server on $(date) in ~/Backup_Git_server
echo Running Rsync
set -o xtrace
rsync -avz --delete --exclude=/mnt/junk --exclude=/mnt/log wcuser@10.10.10.100:/mnt ~/Backup_Git_server
status=$?
set +o xtrace

if [ "$status" == 0 ];then
 echo "Backup successful"
else
 echo "Looks like backup failed"
fi

echo "****************************************"
