#!/bin/bash

LOG=/mnt/log

func fetch {

  #Get all the parameters

  IP=$1;
  filepath=$2
  copy_to_this_dir=$3

  scp -r $(logname)@${IP}:${filename} . &> ${LOG}
  scp_status=$( echo $? )

  filename=`basename $filename`

  if [ "${scp_status}" == 0 ]; then
    while read line
    do
        IP_in_File=$(echo $line | awk '{print $1}'
        fileName_in_File=$(echo $line | awk '{print $2}'
        scp $(logname)@${IP_in_File}:${fileName_in_File} ${copy_to_this_dir} &> ${LOG}
    done < ${filename}
  else
    echo scp failed. might wanna take a look in the ${LOG}
    exit 1
  fi
}
