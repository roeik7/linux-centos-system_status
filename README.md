# linux-centos-system_status
# Description : This script gets a file name as parameter and run system tests by the paramater gets in file.
# Input	       : config file name
# Exit code     : 0 - legal result. 1 - there is a deviation from the threshold. 2 - wrong input (fiile name, number of parameters, wrong paramaters .etc)
# ---------------


update_severity_statistics()
get_sign() 
is_valid_threshold()
is_valid_sign()
is_valid_severity()
rpm_size() 
file_system_usage()
docker_images() 
open_ports() 
logged_in_users() 
threads_per_processes ()
swap_usage()
mem_usage()
cpu_usage() 
execute_verification()
check_file_exist() 
print_test_statistics()
