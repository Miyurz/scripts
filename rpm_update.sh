

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
#	Usage:
#
#		rh-errata -v ver [-i] [-d dir] [-k kern] [-m user] [-n attempts]
#
#		rh-errata -v ver -r [-d dir] [-m user]
#
#		rh-errata -v ver -c [-d dir] [-m user]
#
#		rh-errata -h | --help
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
#	Examples:
#
#		rh-errata -v 6.0
#
#			Retrieve all RPM files for version 6.0 that have not
#			already been downloaded. Use this method if you wish
#			to maintain a complete mirror of updates.  If the
#			incoming directory /usr/local/lib/RH6.0-errata does
#			not exist, the user will be prompted to create it.
#
#		rh-errata -v 6.0 -n 50
#
#			Like above, except attempt download 50 times with a
#			one minute delay between attempts.  This is good for
#			getting updates from busy sites.
#
#		rh-errata -v 6.2 -i
#
#			Retrieve RPM files for version 6.2 using "intelligent
#			mode".  In this mode, rh-errata will only download
#			packages that are installed on the machine running
#			rh-errata.  The intelligent mode also sets the kernel
#			architecture (overriding the -k option) automatically
#			from the value return from the "arch" command.  Use
#			intelligent mode if you are only maintaining a single
#			machine.  If the incoming directory
#			/usr/local/lib/RH6.2-errata does not exist, the user
#			will be prompted to create it.
#
#		rh-errata -v 5.2 -r -m root
#
# 			Check which files in the 5.2 directory need to be
#			installed and mail the report to the superuser.  If
#			the incoming directory /usr/local/lib/RH5.2-errata
#			does not exist, the script will terminate with an
#			error.
#
#		rh-errata -v 6.2 -c
#
#			The "-c" option performs just like the "-r" option
#			except that any package that is obsolete (meaning that
#			there is newer package already installed) or corrupt
#			(meaning that it fails the md5 checksum test) is 
#			deleted from the respository.  This option is useful
#			for cleaning out old stuff that will build up over time.
#
#		rh-errata -v 6.0 -k i686 -d $HOME/rpms
#
#			Retrieve RPM files for version 6.0 and kernel 
#			architecture i686 and place them in
#			$HOME/rpms/RH6.0-errata rather than the default
#			directory /usr/local/lib/RH6.0-errata.  If the
#			directory $HOME/rpms does not exist, the script will
#			terminate with an error.
#						
#	Revisions:
#
#	01/02/2000	File created
#	01/11/2000	Fixed typo
#	03/04/2000	Changed default ftp site to ftp.freesoftware.com
#       03/18/2000      Changed default ftp site to ftp.valinux.com
#	06/27/2000	Added support for kernel architecture and noarch
#	07/04/2000	Changed ftp site back to ftp.freesoftware.com
#	07/21/2000	Changed ftp site back to ftp.valinux.com
#	07/23/2000	Added *UNKNOWN* package status indicating that
#			rpm crashed during an inquiry.  I see this problem
#			on my 5.2 box. (1.0.1)
#	11/23/2000	Added "intelligent mode" and made misc cleanups.
#			(1.1.0)
#	03/30/2001	Updated VA Linux ftp site path (1.1.1)
#	04/01/2001	Added -c option to remove obsolete and corrupt
#			packages from the respository. (1.2.0)
#	09/29/2001	Changed default ftp site to ftp1.sourceforge.net
#			as previous default is no longer available. (1.2.1)
#	01/12/2002	Changed default ftp site to distro.ibiblio.org
#			as previous default is no longer available (1.2.2)
#	02/09/2002	Cosmetic fixes. (1.2.3)
#	07/25/2002	Added -n option for multiple download attempts
#			(1.2.4)
#
#	$Id: rh-errata,v 1.7 2002/07/28 12:50:08 bshotts Exp $
###########################################################################


###########################################################################
#	Constants
###########################################################################

# Also see function retrieve_files (below) for constants specific to the
# ftp site

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
