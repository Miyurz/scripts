#!/bin/bash

supportEmail="support@myorganisation.com"
supportURL="https://support.organisation.com"

bold=$(tput bold)
normal=`tput sgr0`
underline=`tput smul`
nounderline=`tput rmul`

# Obtain the core rpm version.
product_core_version=$(rpm -qa &> /dev/null | grep product_mysql) &> /dev/null

# /proc/loadavg provides us the system load statistics for the last 1,5 and 15 minutes.
# We are just considering the system load for the last five minutes. If you want to change
# it for the last 1 or 15 minutes, change the argument number to 1 or either 3.
sysLoad=$(cat /proc/loadavg | awk '{print $2}')

# Calculate total used memory
free=$(cat /proc/meminfo | grep MemFree | awk '{ print $2}' )
total=$(cat /proc/meminfo | grep MemTotal | awk '{ print $2 }' )
usedMemory=$( expr ${total} - ${free} )
memUsage="$(bc <<< " scale = 2; ( ${usedMemory} / ${total} ) * 100 ") %"

#Calculate swap used memory
freeSwap=$(cat /proc/meminfo | grep SwapFree | awk '{ print $2}' )
totalSwap=$(cat /proc/meminfo | grep SwapTotal | awk '{ print $2}' )
usedSwapMemory=$( expr ${totalSwap} - ${freeSwap} )
swapMemUsage="$(bc <<< " scale = 2; ( ${usedSwapMemory} / ${totalSwap} ) * 100 ") %"

#Calculate the number of product processes
Processes=$(ps aux | grep product | wc -l)

#Calculate number of cores available in the machine
availableCores=$( cat  /proc/cpuinfo | grep processor | wc -l )

#Calculate number of cores user is licensed to use.
#productLicensedCores=$(sudo openssl rsautl -verify -inkey /opt/product/keys/lb_pub.key -in /opt/product/license/product_license.lic -pubin | awk 'NR==2')
productLicensedCores=$(expr ${availableCores} - 1 )

echo -e "\n\t\t${underline}Welcome to ${bold}My Product${normal} ${nounderline},${product_core_version} \n"
echo -e "\t\tSystem information (as of $(date))\n"
echo -e "\t\tSystem load:  ${sysLoad}           Memory usage: ${underline}${memUsage}${nounderline}"
echo -e "\t\tProcesses:    ${Processes}             Swap usage: ${underline}${swapMemUsage}${nounderline}"
echo -e "\t\tAvailable Cores: ${availableCores}          Licensed Cores: ${productLicensedCores}"

echo -e "\n\t\tFor any support issues, please contact us at ${supportEmail} or visit us at: ${supportURL}"
