#!/bin/bash
# ---------------
# Description : This script gets a file name as parameter and run system tests by the paramater gets in file.
# Input	       : config file name
# Exit code     : 0 - legal result. 1 - there is a deviation from the threshold. 2 - wrong input (fiile name, number of parameters, wrong paramaters .etc)
# ---------------

#defining and initialize variable

# constants
little="<"
bigger=">"
h_severity="H"
m_severity="M"
l_severity="L"


#global vars for the checks
h_severity_passed=0
h_severity_failed=0
m_severity_passed=0
m_severity_failed=0
l_severity_passed=0
l_severity_failed=0



update_severity_statistics() # 1 verification result  2 severity
{
	if [ $1 -ne 2 ];then
		case $2 in
		"H")
			if [ $1 -eq 0 ];then
				h_severity_passed=`expr $h_severity_passed + 1`
			else
				h_severity_failed=`expr $h_severity_failed + 1`
			fi ;;
		"M")
			if [ $1 -eq 0 ];then
				m_severity_passed=`expr $m_severity_passed + 1`
			else
				m_severity_failed=`expr $m_severity_failed + 1`
			fi ;;
		"L")
			if [ $1 -eq 0 ];then
				l_severity_passed=`expr $l_severity_passed + 1`
			else
				l_severity_failed=`expr $l_severity_failed + 1`
			fi ;;
		esac
	fi	
		
}



get_sign() # arg - 1 sign
{
	case "$1" in
	"<") echo "-lt" ;;	
	">") echo "-gt" ;;	
	esac
}


is_valid_threshold() # first arg - threshold , sec arg - line
{

	if [[ "$1" =~ ^[0-9]+$ ]] && [ $1 -ge 0 ] && [ $1 -le 100 ]; then
		return 0
	else
		echo "$1: threshold is invalid in $2"
		return 2
	fi

}


is_valid_sign()  # fisst arg - severity , sec arg - line
{
	if [ $1 = $little ]; then
		return 0
	elif [ $1 = $bigger ]; then
		return 0
	else
		echo "$1: invalid sign, in $2 "
		return 2
	fi
}


is_valid_severity() # fisst arg - severity , sec arg - line
{

	if [[ $1 = "H" ]] || [[ $1 = "M" ]] || [[ $1 = "L" ]]; then
		return 0
	else
		echo -e "$1 severity is invalid, in $2\nThe options are: H / M / L ."
		return 2
	fi

}




rpm_size() # args: severity, sign, threshold
{
	rpms_sizes=`rpm -qai | egrep '^Size' | awk '{ print $3 }'`
	sign=$(get_sign "$2")
	threshold=$3


	for rpm_size in $rpms_sizes; do
		rpm_size=`expr $rpm_size / 1024 / 1024 / 1024`		

		if [ $rpm_size $sign $threshold ]; then
			echo -e "Alert : rpm size deivation: rpm size: ${rpm_size}GB $sign ${threshold}GB.\n"
			return 1
			break
		fi
	done

	return 0

}


file_system_usage()
{
	files_system_usage=`df -a | awk '{ print $5 }' | tail -n +2 | sed '/^-/d'`  #filter lines begins with '-'
	sign=$(get_sign "$2")
	threshold=$3

	while read line;do
		usage=`echo $line | cut -d'%' -f1` 
		if [ $usage $sign $threshold ];then
			echo -e "Alert: deviation from usage threshhold. $usage $sign $threshold (threshhold).\n"
			return 1
		fi
	done <<< "$usages"

	return 0

}


docker_images() # args: 1- severity , 2- sign , 3- threshold
{

	dockers_amount=`docker container ls -a | awk '{if(NR>1)print}' | awk '{print $1}' | wc -l`
	sign=$(get_sign "$2")
	threshold=$3

	if [ $dockers_amount $sign $threshold ];then
		echo -e "Alert : Dockers images amount deviation: $dockers_amount $sign $threshold (threshhold).\n".
		return 1
	fi
	
	return 0

}


open_ports() # args: 1- severity , 2- sign , 3- threshold
{
	open_ports_num=`netstat -l | wc -l`
	sign=$(get_sign "$2")
	threshold=$3
	if [ $open_ports_num $sign $threshold ];then
		echo -e "Alert: oper ports number deviation - $open_ports_num $sign $threshold (threshold).\n" 
		return 1
	fi
	
	return 0
}


logged_in_users() # args: 1- severity , 2- sign , 3- threshold
{
	
	users=`who| wc -l`
	sign=$(get_sign "$2")
	threshold=$3
	if [ $users $sign $threshold ];then
		echo -e "Alert: logged in user deviation - users: $users $sign $threshold (threshold).\n"
		return 1
	fi
	
	return 0

}



threads_per_processes () # 1- severity , 2- sign , 3- threshold
{

	processes_pids=`ps -ef | awk 'NR>1 { print $2 }'`
	sign=$(get_sign "$2")
	threshold=$3


	for pid in $processes_pids; do
		threads_amount=`ps -T -p $pid | wc -l`
		if [ $threads_amount $sign $threshold ];then  #if there is a deviation from the threshold
			echo -e "Alert: threads in process deviation - pid : $pid $sign $threshold (threshold).\n"
			return 1
			break
		fi
	done
	
	return 0
}


swap_usage() # args: 1- severity , 2- sign , 3- threshold
{	
	#-m for convert to mb
	free_swap_mb=`free -m | grep Swap | awk '{print $4}'`
	sign=$(get_sign "$2")
	threshold=$3
	
	if [ $free_swap_mb $sign $threshold ];then
		echo -e "Alert: swap usage deviation - free swap in mb : $free_swap_mb $sign $threshold (threshold).\n"
		return 1
	fi
	
	return 0
}


mem_usage() # 1- severity , 2- sign , 3- threshold
{
	free_mem_mb=`free -m | grep Mem | awk '{ print $4 }'`
	sign=$(get_sign "$2")
	threshold=$3

	if [ $mem_usage_percentage $sign $threshold ];then
		echo -e "Alert: memory usage deviation - free memory in mb: $free_mem_mb $sign $threshold (threshold).\n"
		return 1
	fi
	
	return 0

}


cpu_usage() # 1- severity , 2- sign , 3- threshold
{
	cpu_idle=`mpstat 3 1| grep Average| awk '{idle=int($12); print idle}'`
	sign=$(get_sign "$2")
	threshold=$3
	if [ $cpu_idle $sign $threshold ];then
		echo -e "Alert: cpu usage deviation: cpu idle - $cpu_idle $sign $threshold (threshold).\n"		
		return 1
	fi
	
	return 0

}



execute_verification() # 1 - verification , 2 - sevrity , 3 - sign , 4 - threshold
{
	case $1 in
	 "logged_in_users" | "threads_per_processes" | "open_ports" | "rpm_size" | "docker_images" | "file_system_usage" | "cpu_usage" | 		 	"swap_usage" | "logged_in_users" | "mem_usage" ) 
		"$1" "$2" "$3" "$4"
		;;
	*) #in case the verfiction not one of the options
		echo "the verification you entered: $1 - is invalid"
		return 2
		;;
	esac
	return $?

}





check_file_exist() # args: 1- file name
{

	if [ "$1" = "" ]; then #empty string
		echo "you have to enter file name in -p flag"
		exit 2
	
	elif [[ ! -f "$1" ]]; then  #if not exist
		echo "The conig file is not found"
		exit 2

	fi
}


print_test_statistics()
{
	
	echo "High severity passed: $h_severity_passed, failed: $h_severity_failed."
	echo "Medium severity passed: $m_severity_passed, failed: $m_severity_failed."
	echo "Low severity passed: $l_severity_passed, failed: $l_severity_failed."

}

	
# -------- main of the script --------- 

	while getopts 'c:' flag; do

  		case "$flag" in

  		  c) file_name="${OPTARG}" ;;
  		  *) echo "flags are invalid"
		     exit 1;;

  		esac
	done


	check_file_exist "$file_name"

	while read line; do
	if [ ! -z "$line" ] && [[ ! "$line" =~ ^# ]]; then #not empty line and not comment line
		severity=`echo $line | cut -d ' ' -f1`
		verification=`echo $line | cut -d' ' -f2`
		sign=`echo $line | cut -d' ' -f3`
		threshold=`echo $line | cut -d' ' -f4 | cut -d'%' -f1` 

		is_valid_severity "$severity" "$line"
		severity_is_valid=$?
		is_valid_sign "$sign" "$line"
		sign_is_valid=$?
		is_valid_threshold "$threshold" "$line"
		threshold_is_valid=$?

		
		if [ $severity_is_valid -eq 0 ] && [ $sign_is_valid -eq 0 ] && [ $threshold_is_valid -eq 0 ]; then			

			execute_verification "$verification" "$severity" "$sign" "$threshold"
			update_severity_statistics $? "$severity"
	
		fi
		
	fi
	done < "$file_name"
	


	print_test_statistics
	
	exit 0