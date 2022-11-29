#!/bin/bash
# function: File rename
# version: 1.0

exec_hostname=${HOSTNAME:-$1}
base_home=$(dirname $0)
log_dir="$base_home/logs"
mkdir -p $log_dir
log_file="$log_dir/log_$(date "+%Y%m%d").log"

log_r(){
	exec_time=$(date "+%Y-%m-%d %H:%M:%S")
	echo "$exec_time $exec_hostname $1"
}

check_input(){
	if [[ -z $1 ]]; then
		log_r 'Invalid parameter'
		exit 1
	fi
}

check_file_state(){
	if [[ -d $1 ]]; then
		log_r "\"$1\" is a directory"
		exit 1
	fi
	if [[ ! -a $1 ]]; then
		log_r "\"$1\" file not exist"
		exit 1
	fi
}

do_file_rename(){
	FILE_PATH=$1
	BASE_PATH=$(dirname $FILE_PATH)
	FILE=$(basename $FILE_PATH)
	OLD_FILE=$FILE_PATH
	NEW_FILE=$BASE_PATH/${HOSTNAME}_$(date "+%Y%m%d%H%M%S").hprof
	mv $OLD_FILE $NEW_FILE
	if [[ $? -eq 0 ]]; then
		log_r "Rename Successful. Rename $OLD_FILE to $NEW_FILE"
	else
		log_r "Rename Failed. Rename $OLD_FILE to $NEW_FILE"
	fi
}

main(){
	log_r 'Start rename task.'
	check_input $1
	check_file_state $1
	do_file_rename $1
}

main "$@"|tee -a ${log_file}
