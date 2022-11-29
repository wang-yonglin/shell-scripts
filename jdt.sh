#!/bin/bash
# JDT(Java Diagnose Toolsuite)
# function: Diagnose JVM by one key.
# version: 1.0
#
PID=${1:-1}
exec_hostname=${HOSTNAME}
base_home=/opt/agents/java-dump/diagnose/$(date "+%Y-%m-%d")/$exec_hostname
log_dir="$base_home/logs"
report_dir="$base_home/report"
log_file="$log_dir/jdt-log-$(date "+%Y%m%d").log"
exec_timedate=$(date "+%Y%m%d-%H%M%S")


log_r(){
	exec_time=$(date "+%Y-%m-%d %H:%M:%S")
	printf "$exec_time - $exec_hostname - $1\n"
}

init_dir(){
	if [[ ! -d "$log_dir" ]]; then
		mkdir -p $log_dir
		if [[ $? -ne 0 ]]; then
			printf "$log_dir directory create failed.\n"
			exit 1
		fi
	fi

	if [[ ! -d "$report_dir" ]]; then
		mkdir -p $report_dir
		if [[ $? -ne 0 ]]; then
			printf "$report_dir directory create failed.\n"
			exit 1
		fi
	fi

}

is_pid_exist(){
	if [[ -z $PID ]]; then
		log_r "Invalid parameter, PID is null"
		exit 1
	fi
	java_pid=$(jcmd -l|grep -v JCmd|awk '{print $1}'|grep -w $PID)
	if [[ -z $java_pid ]]; then
		log_r "No such process, pid: $PID"
		exit 1
	fi
}

is_cmd_exist(){
	type $1 >/dev/null 2>&1
	if [[ $? -ne 0 ]]; then
		log_r "$1 not support."
		exit 1
	fi

}

check_env(){
	is_cmd_exist jcmd
	is_pid_exist
	is_cmd_exist jstack
	is_cmd_exist jmap
}

get_jstack(){
	for loop_times in {1..3}
	do
		log_r "jstack $loop_times times and to sleep 2 seconds."
		jstack -l $PID > $report_dir/jstack-$PID-$exec_timedate-$loop_times.txt
		sleep 2
	done
	log_r "jstack report exported."
}

deadlock_check(){
	log_r "jstack deadlock checking,please wait."
	jstack -l -F $PID > $report_dir/jstack-deadlock-$PID-$exec_timedate.txt
	log_r "jstack deadlock report exported."
}

get_gc(){
	log_r "generating gc statistics report,please wait."
	echo "#jstat -gc -t $PID 1000 10" > $report_dir/gc-$PID-$exec_timedate.txt
	jstat -gc -t $PID 1000 10 >> $report_dir/gc-$PID-$exec_timedate.txt
	echo "#jstat -gccause $PID" >> $report_dir/gc-$PID-$exec_timedate.txt
	jstat -gccause $PID >> $report_dir/gc-$PID-$exec_timedate.txt
	echo "#jstat -gcnew $PID" >> $report_dir/gc-$PID-$exec_timedate.txt
	jstat -gcnew $PID >> $report_dir/gc-$PID-$exec_timedate.txt
	echo "#jstat -gcold $PID" >> $report_dir/gc-$PID-$exec_timedate.txt
	jstat -gcold $PID >> $report_dir/gc-$PID-$exec_timedate.txt
	log_r "gc statistics report created."
}

get_jvm_heap(){
	log_r "JVM heap exporting."
	jmap -heap $PID > $report_dir/jvm-heap-$PID-$exec_timedate.txt
	log_r "JVM heap exported."
}

get_jvm_dump(){
	log_r "JVM heap dump file exporting."
	jmap -dump:format=b,file=$report_dir/jvm-heap-dump-$PID-$exec_timedate.hprof $PID >> ${log_file}
	log_r "JVM heap file exported."
}

start_jfr(){
	log_r "Start JFR, it will keep recording for 5 minutes and exit automatically."
	jfr_filename=jfr-$PID-$exec_timedate.jfr
	jcmd $PID VM.unlock_commercial_features >> ${log_file}
	jcmd $PID JFR.start duration=5m filename=$report_dir/$jfr_filename compress=true dumponexit=true name=jfr_$exec_timedate >> ${log_file}
	jcmd $PID JFR.check >> ${log_file}
	log_r "JFR started, recording JFR file to $report_dir/$jfr_filename"
	
}

main(){
	printf "JDT version 1.0\n"
	log_r "Start diagnose. PID: $PID"
	log_r "Report file output: $report_dir"
	check_env
	get_jstack
	#线程线死锁检测当前java基础镜像会卡住,暂关闭
	#deadlock_check
	get_gc
	get_jvm_heap
	get_jvm_dump
	start_jfr
	log_r 'Diagnose finished.'
}
init_dir
main "$@"|tee -a ${log_file}

