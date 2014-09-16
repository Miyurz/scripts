#!/bin/bash

YUM_REPO=Product_Repo_6.4
declare -a PRODUCT_PACKAGES=(product_analytics product_mysql product_ui product_utils);
declare -a YUM_SERVER_PACKAGE_MAPPING=(package_name package_version repository);

# This function gets the list of available packages on the yum server and encodes it in JSON format.
# Turn of the echoes if you aren't debugging.
function get_product_packages() {

   #Clear off the cached data
   sudo yum clean all --quiet
   JSON_OBJECT="{'packages':
                 {"
   #echo -e "\n"

   for package in "${PRODUCT_PACKAGES[@]}"
   do
     j=0
        #Query for the latest product packages
        for i in $(yum --disablerepo="*" --enablerepo=${YUM_REPO} list available | grep ${package} )
        do
          #echo "${YUM_SERVER_PACKAGE_MAPPING[$j]} is "$i

          if [ $j == 0 ]
          then
             #echo "${YUM_SERVER_PACKAGE_MAPPING[$j]} is "$i
             package_version=${i}
             package_name=$(echo "${package_version}" | cut -d "." -f 1)
             arch_type=$(echo "${package_version}" | cut -d "." -f 2)
             #echo Version 1 is : ${package_version}
          elif [ $j == 1 ]
          then
             #echo "${YUM_SERVER_PACKAGE_MAPPING[$j]} is "$i
             package_version=${package_name}-${i}.${arch_type}
          fi

          j=$( expr $j + 1 )
        done
     #echo "Package: ${package}'s latest available version on yum is : ${package_version}"
     JSON_OBJECT="${JSON_OBJECT} '${package}':'${package_version}',"
	 package_version=""
     package=""
	 #echo "-------------------------"
   done
   JSON_OBJECT="${JSON_OBJECT} }
                               }"
   echo ${JSON_OBJECT} | sed 's/, *} *} *$/ } }/g'
}

#This function installs the list of packages provided to it in an array.
function install_packages() {
    declare -a packages_to_be_installed=("${!1}")
    for rpm in "${packages_to_be_installed[@]}"
    do
       echo "I will install the rpm, ${rpm}"
       yum upgrade -y ${rpm}

	   core_rpm="^product_mysql.*"
	   ui_rpm="^product_ui.*"

	   if [[ "${rpm}" =~ ${core_rpm} ]]
	   then
	      echo "Found core rpm. Hence, restarting it".
		  /opt/product/bin/stop_product
		  usleep 16
		  /opt/product/bin/start_product
	   else
		  echo "Some other rpm."
	   fi
    done
}

#This function lets the user know how to use the script.
function usage(){
   echo -e "This script lets you know what all product packages are available for upgrade on yum server and helps you install them all or selectively."
   echo -e "You can run it with the following options :"
   echo -e "1)  ./yum_installer.sh -n"
   echo -e "2)  ./yum_installer.sh -a"
   echo -e "3)  ./yum_installer.sh -i <package_1> <package_2> <package_3> ..."
}

function update_table_for_historical_stats() {

	#Recording changes to be displayed in historical stats for UI
	#First, create the table if it doesn't exist
        #Now, Record the machine state post installation in the table.
	sudo sqlite3 /system/lb.sqlite 'CREATE TABLE IF NOT EXISTS `product_software_version` ( `Id` INTEGER PRIMARY KEY AUTOINCREMENT,
	                                `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP,`UI_version` VARCHAR(250),`iDB_type` VARCHAR(20),`rpm_list` text,
									`package` VARCHAR(250),status VARCHAR(100)  );' 2> /tmp/sql_log
	iDB_Type="MySQL"
	package="NULL"
        UI_RPM_VERSION=$(rpm -qa | grep product_ui)
	echo "UI's rpm version is ${UI_RPM_VERSION}"
	rpm_list=$(rpm -qa | egrep "^product_(ui|mysql|utils|analytics)" )
	rpm_list=$(echo $rpm_list  | sed -e "s/ /,/g")
	sudo sqlite3 /system/lb.sqlite "INSERT INTO product_software_version (UI_version,iDB_type,rpm_list,package,status)
                                                             VALUES
															 (\"${UI_RPM_VERSION}\",\"${iDB_Type}\",\"${rpm_list}\",\"NULL\",\"SUCCESS\");" 2>> /tmp/sql_log
}

if [ "$1" == "-n" ]
then
    echo "Calling the function get_product_packages to obtain list of new rpms available in the yum repository."
    get_product_packages

elif [ "$1" == "-a" ]
then
    echo "Calling the function install_packages to install all the packages"
    install_packages PRODUCT_PACKAGES[@]
    update_table_for_historical_stats

elif [ "$1" == "-i" ]
then
    echo "Calling the function install_packages to install selective packages"
    no_of_rpms_to_be_installed=$( expr $# - 1 )

    if [ "${no_of_rpms_to_be_installed}" == 0 ];
    then
       echo "You chose the option -i. So you need to tell me what all packages need to be installed. Exiting now ..."
       exit 1
    fi

    echo "I need to install ${no_of_rpms_to_be_installed} rpms."
    declare -a USER_SPECIFIED_PACKAGES

    k=0;
       for a in ${BASH_ARGV[*]} ; do
         echo -e "k -s $k"

          if [ "$k" == "${no_of_rpms_to_be_installed}" ]
          then
             echo "I have reached last the last element. Quitting from the loop."
             break;
          else
             USER_SPECIFIED_PACKAGES[$k]=$a
          fi

         k=$( expr $k + 1 )
         echo -e "Element is $a \n"
       done
    install_packages USER_SPECIFIED_PACKAGES[@]
    update_table_for_historical_stats

else
   echo "Unknown option passed."
   usage
   exit 1
fi

