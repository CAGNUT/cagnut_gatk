#!/bin/bash

cd "#{jobs_dir}/../"
echo "#{script_name} is starting at $(date +%Y%m%d%H%M%S)" >> "#{jobs_dir}/finished_jobs"
if [ ! -s "#{bqsr_file}" ]; then
 echo "Error: missing recalfile #{bqsr_file}"
 exit 100
fi

rm core.* 2> /dev/null

#{print_reads_params['java'].join("\s")} \\
  #{print_reads_params['params'].join(" \\\n  ")} \\
  #{run_local}

EXITSTATUS=$?

# throw error if < 1024 bytes
if [ $(stat --printf="%s" "#{output}") -le 1024 ]
then
  exit 100
fi
echo "#{script_name} is finished at $(date +%Y%m%d%H%M%S)" >> "#{jobs_dir}/finished_jobs"

exit $EXITSTATUS
