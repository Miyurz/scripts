

#!/bin/bash

###########################################################################
#
#	Shell program to download updates for RH Linux from an FTP site.
#

#
#	Description:
#
#	This program is used to get update and errata files from an
#	ftp site (presumably a mirror of Red Hat's own site).  In
#	addition to downloading RPM files, this program will also
#	report on the status of the system compared to the contents
#	of the incoming directory (assumed to be under /usr/local/lib).
#	By using this feature you can determine which downloaded RPM
#	files need to be installed.
#
#	See the function retrieve_files (below) for constants used to
#	define the name of the ftp site and the source directory on the
#	remote site. 
#
#	NOTE: You must be the superuser to run this script since you will
#	likely wish to download the RPM files into a directory that is
#	not world writable (such as /usr/local/lib).
#
#
#
#	Options:
#
#		-v ver		Get updates for version "ver".
#		-i		Intelligent mode
#		-d dir		Set root directory for download.
#				Defaults to "/usr/local/lib".
#		-k kernel	Kernel architecture "kern"
#		-m user		Mail results to "user".
#		-n attempts	Retry downloads "attempts" times.
#		-r		Report which updates need to be applied.
#		-c		Clean repository of obsolete and corrupt
#				packages.
#		-h, --help	Display this help message and exit.
#


###########################################################################
#	Constants
###########################################################################


PROGNAME=$(basename $0)
VERSION="1.2.4"
if [ -d ~/tmp ]; then
	TEMP_DIR=~/tmp
else
	TEMP_DIR=/tmp
fi
DEFAULT_INCOMING_ROOT=/usr/local/lib	# change this if desired
PLATFORM=i386				# change this if platform != Intel
ATTEMPT_DELAY=60
TEMP0=${TEMP_DIR}/${PROGNAME}_0.$$.$RANDOM
TEMP1=${TEMP_DIR}/${PROGNAME}_1.$$.$RANDOM
TEMP2=${TEMP_DIR}/${PROGNAME}_2.$$.$RANDOM
TEMP3=${TEMP_DIR}/${PROGNAME}_3.$$.$RANDOM


###########################################################################
#	Functions
###########################################################################


function clean_up
{

	#####	
	#	Function to remove temporary files and other housekeeping
	#	No arguments
	#####

	rm -f ${TEMP0} ${TEMP1} ${TEMP2} ${TEMP3}
}


function graceful_exit
{
	#####
	#	Function called for a graceful exit
	#	No arguments
	#####

	clean_up
	exit
}


function error_exit 
{
	#####	
	# 	Function for exit due to fatal program error
	# 	Accepts 1 argument
	#		string containing descriptive error message
	#####

	local err_msg
	
	err_msg="${PROGNAME}: ${1}"
	echo ${err_msg} >&2
	clean_up
	exit 1
}


function term_exit
{
	#####
	#	Function to perform exit if termination signal is trapped
	#	No arguments
	#####

	echo "${PROGNAME}: Terminated"
	clean_up
	exit
}


function int_exit
{
	#####
	#	Function to perform exit if interrupt signal is trapped
	#	No arguments
	#####

	echo "${PROGNAME}: Aborted by user"
	clean_up
	exit
}


function usage
{
	#####
	#	Function to display usage message (does not exit)
	#	No arguments
	#####

	echo "Usage:"
	echo "	${PROGNAME} -v version [-i] [-d dir] [-k kernel] [-m user] [-n attempts]"
	echo "	${PROGNAME} -v version -r [-d dir] [-m user]"
	echo "	${PROGNAME} -v version -c [-d dir] [-m user]"
	echo "	${PROGNAME} -h | --help"
}


function helptext
{
	#####
	#	Function to display help message for program
	#	No arguments
	#####
	
	local tab=$(echo -en "\t\t")
		
	cat <<- -EOF-
	
	${PROGNAME} ver. ${VERSION}	
	This program downloads updates for RH Linux from an FTP site.
	
	$(usage)
	
	Options:
	
	-v ver		Get updates for "version".
	-i		Intelligent mode
	-d dir		Set root directory for download.
			${tab}Defaults to "/usr/local/lib".
	-k kernel	Kernel platform (example i586)
	-m user		Mail results to "user".
	-n attempts	Retry downloads "attempts" times.
	-r		Report which updates need to be applied.
	-c		Clean respository of obsolete and
			${tab}corrupt packages.
	-h, --help	Display this help message and exit.
	
			
	NOTE: You must be the superuser to run this script.
		
	-EOF-
}	


function root_check
{
	#####
	#	Function to check if user is root
	#	No arguments
	#####
	
	if [ "$(id | sed 's/uid=\([0-9]*\).*/\1/')" != "0" ]; then
		error_exit "You must be the superuser to run this script."
	fi
}


function package_name
{
	#####
	#	Given an RPM file name, returns package name
	#	Arguments:
	#		1	RPM file name (required)
	#####

	# Fatal error if required arguments are missing

	if [ "$1" = "" ]; then 
		error_exit "package_name: missing argument 1"
	fi

	echo $1 | awk '
	
		BEGIN {
			FS = "-"
		}
		
		NF == 3 {
			print $1
		}
		
		NF > 3 {
			printf("%s", $1)
			for (i = 2; i <= ( NF - 2 ); i++) {
				printf("-%s", $i)
			}
			print ""
		}
	'
}	# end of package_name


function package_needed
{
	#####
	#	Returns 0 if package is installed on system
	#	Arguments:
	#		1	package name (required)
	#####

	# Fatal error if required arguments are missing

	if [ "$1" = "" ]; then 
		error_exit "package_needed: missing argument 1"
	fi

	rpm -q $1 2>&1
	return $?
	
}	# end of package_needed


function check_rpm_integrity
{
	#####
	#	Returns 0 if RPM package file is not corrupted
	#	Arguments:
	#		1	package file name (required)
	#####

	# Fatal error if required arguments are missing

	if [ "$1" = "" ]; then 
		error_exit "check_rpm_integrity: missing argument 1"
	fi

	# Note: this assumes rpm version > 3.  To use with earlier versions
	# remove "--nogpg"
	
	rpm --checksig --nopgp --nogpg $1 2>&1
	return $?

}	# end of check_rpm_integrity


function installed_package_date
{
	#####
	#	Returns build time of an installed package
	#	Arguments:
	#		1	package name (required)
	#####

	# Fatal error if required arguments are missing

	if [ "$1" = "" ]; then 
		error_exit "installed_package_date: missing argument 1"
	fi

	# Get build time from rpm database - notice "tail" trick to handle
	# when more than one instance of a package is installed.  I assume
	# the last one listed is the most recent.
	
	rpm -q $1 --queryformat "%{BUILDTIME}\n" | tail --lines=1

}	# end of installed_package_date


function file_package_date
{
	#####
	#	Returns build time of a package file
	#	Arguments:
	#		1	package file name (required)
	#####

	# Fatal error if required arguments are missing

	if [ "$1" = "" ]; then 
		error_exit "file_package_date: missing argument 1"
	fi

	rpm -qp $1 --queryformat "%{BUILDTIME}\n"

}	# end of file_package_date


function newest_packages
{
	#####
	#	Generate list of of newest packages
	#	Arguments:
	#		1	Input file (required)
	#		2	Output file (required)
	#####

	# Fatal error if required arguments are missing

	if [ "$1" = "" ]; then 
		error_exit "newest_packages: missing argument 1"
	fi
	if [ "$2" = "" ]; then 
		error_exit "newest_packages: missing argument 2"
	fi

	local input_file=$1
	local output_file=$2
	local curr_pkg=
	local next_pkg=
	local curr_file=
	
	# Sort input file
	
	sort $input_file > $output_file
	cp $output_file $input_file
	> $output_file
	
	# Find newest assuming (perhaps wrongly) that newest sorts higher
	
	for i in $(cat $input_file); do
		next_pkg=$(package_name $i)
		if [ "$next_pkg" != "$curr_pkg" ]; then
			if [ "$curr_file" != "" ]; then
				echo $curr_file >> $output_file
			fi
			curr_pkg=$next_pkg
		fi
		curr_file=$i
	done
	echo $curr_file >> $output_file
	
}	# end of newest_packages


function generate_report
{
	#####
	#	Reports which rpms need to be installed
	#	also removes obsolete and corrupted rpms
	#	if $flag_clean = 1
	#
	#	Arguments:
	#		1	RH Linux version (required)
	#		2	Incoming root directory (required)
	#####

	local version=$1
	local incoming_root=$2
	local INCOMINGDIR=${incoming_root}/RH${version}-errata
	local i
	local status
	local file_time
	local package_time
	local pkg_name

	# Fatal error if required arguments are missing

	if [ "$1" = "" ]; then 
		error_exit "generate_report: missing argument 1"
	fi

	if [ ! -d ${INCOMINGDIR} ]; then
		error_exit "generate_report: no such version directory on system"
	fi
	
	cd ${INCOMINGDIR} || error_exit "generate_report: cannot change to incoming directory"

	echo -e "\nPackage Status Report - $(date)"
	echo -e "Version: ${version}\n\n"
	
	for i in *.rpm ; do
		status="*UNKNOWN*"
		if check_rpm_integrity $i > /dev/null; then
			pkg_name=$(package_name $i)
			if package_needed $pkg_name > /dev/null; then
				file_time=$(file_package_date $i)
				package_time=$(installed_package_date $pkg_name)
				if [ "$file_time" -gt "$package_time" ]; then
					status="*INSTALLATION NEEDED*"
				fi
				if [ "$file_time" -lt "$package_time" ]; then
				
					# If -c option set, delete obsolete package
					
					if [ $flag_clean = "1" ]; then
						rm $i
						status="*OBSOLETE PACKAGE DELETED*"
					else
						status="Obsolete"
					fi
				fi
				if [ "$file_time" -eq "$package_time" ]; then
					status="Already installed"
				fi
			else
				status="Not needed"
			fi
		else
			if [ $flag_clean = "1" ]; then
				rm $i
				status="*CORRUPT PACKAGE DELETED*"
			else
				status="*PACKAGE CORRUPT*"
			fi
		fi
		printf "%-45s: %s\n" $i "$status"
	done

}	# end of generate_report


function retrieve_files
{
	#####
	#	Downloads files from FTP site
	#	Arguments:
	#		1	RH Linux version (required)
	#		2	platform/kernel such as i386 (required)
	#		3	incoming root directory (required)
	#####

	local version=$1
	local platform=$2
	local incoming_root=$3

	# These constants are specific to the ftp site used.
	# Edit as needed for your chosen site.
	
	local HOST=distro.ibiblio.org
	local TARGET=/pub/Linux/distributions/redhat/updates/${version}/en/os/${platform}
	local USRNAME=anonymous
	local PASSWD=${USER}@${HOSTNAME}

	local INCOMINGDIR=${incoming_root}/RH${version}-errata
	local file_count=0
	local pkg_name=
	local attempt_count=0
	local es=

	# Fatal error if required arguments are missing

	if [ "$1" = "" ]; then 
		error_exit "retrieve_files: missing argument 1"
	fi

	if [ "$2" = "" ]; then 
		error_exit "retrieve_files: missing argument 2"
	fi

	if [ "$3" = "" ]; then 
		error_exit "retrieve_files: missing argument 3"
	fi
	
	# Create temporary files

	> ${TEMP0}
	> ${TEMP1}
	> ${TEMP2}
	> ${TEMP3}

	# Change to the directory where incoming files will be written

	if [ -d ${INCOMINGDIR} ] ; then
		cd ${INCOMINGDIR} || error_exit "retrieve_files: Incoming directory not available!"
	else
		echo -n "Incoming directory ${INCOMINGDIR} does not exist. Create? [y/n]: "
		read foo
		case $foo in
			y|Y )	mkdir ${INCOMINGDIR} || error_exit "retrieve_files: Cannot create incoming directory!"
				cd ${INCOMINGDIR}
				;;
			*)	error_exit "retrieve_files: No incoming directory available - aborting!"
				;;
		esac
	fi


	# Use ftp to get a directory of the target (remote) directory
	
	while [ $attempt_count -lt $max_attempts ]; do
		echo -e "\nGetting directory from ${HOST}:${TARGET}..."
		echo	"user $USRNAME $PASSWD
			prompt off
			binary
			cd ${TARGET}
			dir *.${platform}.rpm  ${TEMP0}
			bye" | ftp -n ${HOST}

		# Strip off extra stuff from directory listing

		if [ -s ${TEMP0} ]; then
			awk '
				NF==9 && !( $1 ~/^d/ ) {
					print $9
				}

	 		' < ${TEMP0} > ${TEMP1}
			file_count=$(wc -l ${TEMP1} | awk '{ print $1}')
			attempt_count=0
			break
		else
			# If directory file is empty, something went wrong
			
			attempt_count=$((attempt_count + 1))
			if [ $attempt_count -lt $max_attempts ]; then
				echo "Attempt $attempt_count failed, waiting $ATTEMPT_DELAY seconds before retry."
				sleep $ATTEMPT_DELAY
			fi
		fi
	done

	if [ $attempt_count -gt 0 ]; then
		error_exit "retrieve_files: Unable to get directory from ftp server"
	fi
	echo "$file_count files available."

	# Determine which files from the target are needed.

	case $intell_mode in
		NO )	for i in $(cat ${TEMP1}); do
		
				# Check if the file is already in respository
				
				if [ ! -f ${INCOMINGDIR}/${i} ]; then
					echo $i >> ${TEMP3}
					
				else	# Check if existing file in respository is corrupt
				
					if check_rpm_integrity $i > /dev/null; then
						:
					else
						echo $i >> ${TEMP3}
					fi
				fi
			done
			;;
			
		YES )	for i in $(cat ${TEMP1}); do
		
				# Get name of package from RPM database
				
				pkg_name=$(package_name $i)
				
				# Check if file is already in respository
				
				if [ ! -f ${INCOMINGDIR}/${i} ]; then
				
					# Find out if package is installed (i.e. needed)
					
					if package_needed $pkg_name > /dev/null; then
						echo $i >> ${TEMP2}
					fi
					
				else	# Check if existing file in respository is corrupt
				
					if check_rpm_integrity $i > /dev/null; then
						:
					else
						echo $i >> ${TEMP2}
					fi
				fi
			done

			# Find the newest versions of the needed packages
			
			if [ -s $TEMP2 ]; then
				newest_packages $TEMP2 $TEMP3
			fi
			;;
						
		* )	error_exit "retrieve_files: invalid retrieval mode"
	esac
	
	file_count=$(wc -l ${TEMP3} | awk '{ print $1}')
	
	# Check if any files need retrieval
		
	if [ ! -s ${TEMP3} ]; then
		echo "No new files to retrieve."
		return 0
	else
		echo -e "$file_count files needed."
		echo -e "\nAttempting to retrieve the following files:"
		cat ${TEMP3}
	fi

	# Get the files

	echo -e "\nRetrieving files from ${HOST}:${TARGET}..."
	date
	
	# Generate ftp commands and retrieve files

	attempt_count=0
	while [ $attempt_count -lt $max_attempts ]; do
		es=0
		awk -v USER=${USRNAME} -v PASS=${PASSWD} -v TARGET=${TARGET} '

			BEGIN {
				print "user " USER " " PASS
				print "prompt off"
				print "binary"
				print "cd " TARGET
			}

			{
				print "get " $1
			}
	
			END {
				print "bye"
			}

		' < ${TEMP3} | ftp -n ${HOST}

		# Check that all the files were retrieved

		for i in $(cat $TEMP3); do
			if [ ! -r $i ]; then
				attempt_count=$((attempt_count + 1))
				es=1
				if [ $attempt_count -lt $max_attempts ]; then
					echo "Attempt $attempt_count failed, waiting $ATTEMPT_DELAY seconds before retry."
					sleep $ATTEMPT_DELAY
					break
				fi
			fi
		done

		# If retrieval was sucessful, break out of loop

		if [ $es -eq 0 ]; then
			attempt_count=0
			break
		fi
	done

	# Die if we exceeded number of attempts without success

	if [ $attempt_count -ne 0 ]; then
		 error_exit "retrieve_files: Error during file retrieval"
	fi
	echo -e "\nRetrieval complete. $(date)"

}	# end of retrieve_files



###########################################################################
#	Program starts here
###########################################################################

# Set file creation mask so that all files are created with 600 permissions.
# This will help protect temp files.

umask 066
root_check

# Trap TERM, HUP, and INT signals and properly exit

trap term_exit TERM HUP
trap int_exit INT

# Process command line arguments

if [ "$1" = "--help" ]; then
	helptext
	graceful_exit
fi

flag_mail=0
flag_report=0
flag_clean=0
version=
addressee=
incoming_root=$DEFAULT_INCOMING_ROOT
kernel=$PLATFORM
intell_mode=NO
max_attempts=1

while getopts ":v:d:m:k:n:rchi" opt; do
	case $opt in
		v )	version=${OPTARG}
			;;
		d )	incoming_root=${OPTARG}
			;;
		m )	flag_mail=1
			addressee=${OPTARG}
			;;
		n )	max_attempts=${OPTARG}
			;;
		k )	kernel=${OPTARG}
			;;
		r )	flag_report=1
			;;
		i )	intell_mode=YES
			kernel=$(arch)
			;;
		c )	flag_clean=1
			flag_report=1
			;;
		h )	helptext
			graceful_exit
			;;
		* )	usage
			exit 1
			;;
	esac
done

# Version must be set

if [ "$version" = "" ]; then
	error_exit "Red Hat version must be specified! Try '-h' for help."
fi
if [ "$(echo $version | awk '/^[0-9][.][0-9]$/ { print $0 }')" = "" ]; then
	error_exit "Invalid version number format.  Must be in form 'n.n'"
fi

# If major Red Hat version is less than 6, then kernel arch is not supported

if [ $(echo $version | cut -d "." -f 1) -lt 6 ]; then
	kernel=$PLATFORM
fi

# Check that incoming root directory exists

if [ ! -d "$incoming_root" ]; then
	error_exit "Directory $incoming_root does not exist."
fi

# Generate report if "-r" argument passed, otherwise retrieve files

if [ $flag_report = 1 ]; then
	if [ $flag_mail = 1 ]; then
		generate_report $version $incoming_root | mail -s "Package report from ${PROGNAME}" $addressee
	else
		generate_report $version $incoming_root
	fi
else
	if [ $flag_mail = 1 ]; then
		( if [ $kernel != $PLATFORM ]; then
			retrieve_files $version $kernel $incoming_root
		fi
		retrieve_files $version $PLATFORM $incoming_root
		retrieve_files $version noarch $incoming_root) | mail -s "Retrievial report from ${PROGNAME}" $addressee
	else
		if [ $kernel != $PLATFORM ]; then
			retrieve_files $version $kernel $incoming_root
		fi
		retrieve_files $version $PLATFORM $incoming_root
		retrieve_files $version noarch $incoming_root
	fi
fi

graceful_exit
