#!/bin/bash

LOGFILE=${JOB_NAME}-${BUILD_NUMBER}-${BUILD_ID}

function get_details {

echo "Current directory is $(pwd)"
which git 2> /dev/null && echo "git is installed" || echo "git is unavailable"

echo "Capture last 3 commits."
git log -3 |  tee  ${LOGFILE}

}

