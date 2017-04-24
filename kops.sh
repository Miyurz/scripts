#!/bin/bash
set -x
KOPS_KEY="~/.ssh/kops_rsa"

if [ -f ${KOPS_KEY} ]; then
	echo $KOP_KEY exists...
else
	ssh-keygen -b 2048 -t rsa -f ${KOPS_KEY} -q -N ""
fi

clusterName=sre.k8s.io
export AWS_SDK_LOAD_CONFIG=true
export KOPS_STATE_STORE="s3://nonproduction-kops-eu-west-1"
export AWS_PROFILE=nonproduction
aws s3 rm ${KOPS_STATE_STORE} --profile=${AWS_PROFILE}
aws s3 mb ${KOPS_STATE_STORE} --profile=${AWS_PROFILE}

kops delete cluster --name ${clusterName} --yes

kops create cluster --name ${clusterName} --master-size=t2.medium --node-size=t2.medium --bastion --state ${KOPS_STATE_STORE} --zones="ap-south-1a" --ssh-public-key="${KOPS_KEY}".pub --topology=private --networking=weave --associate-public-ip=false --node-count=3 --cloud=aws  --dns-zone=k8s.io --yes
#until [ $(kops validate cluster --name ${clusterName}) -eq 0 ]
#do
#	echo "Sleeping for $i seconds"
#	sleep $i
#done
