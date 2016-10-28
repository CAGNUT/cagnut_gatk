#!/bin/bash

cd "#{jobs_dir}/../"
echo "#{script_name} is starting at $(date +%Y%m%d%H%M%S)" >> "#{jobs_dir}/finished_jobs"
#{count_reads_params['java'].join("\s")} \\
  #{count_reads_params['params'].join(" \\\n  ")} \\
  #{run_local}

EXITSTATUS=$?

if [ ! -s #{output} ]
then
  echo "Incomplete output file #{output}"
  exit 100
fi

if [ $(stat --printf="%s" #{output}) = 100 ];then
  echo "Memory Error. Exitting."
  exit 100
fi
echo "#{script_name} is finished at $(date +%Y%m%d%H%M%S)" >> "#{jobs_dir}/finished_jobs"

if [ $EXITSTATUS -ne 0 ];then exit $EXITSTATUS;fi
