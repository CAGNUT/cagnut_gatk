#!/bin/bash

cd "#{jobs_dir}/../"
echo "#{script_name} is starting at $(date +%Y%m%d%H%M%S)" >> "#{jobs_dir}/finished_jobs"
if [ ! -s #{after} ]; then
 echo "Error: missing recalfile #{after}"
 exit 100
fi

rm core.* 2> /dev/null

#{analyze_covariates_params['java'].join("\s")} \\
  #{analyze_covariates_params['params'].join(" \\\n  ")} \\
  #{run_local}

EXITSTATUS=$?

#throw an error if no output file
if [ ! -s #{output} ];then
  echo "Error: no plots outputted"
  exit 100
fi

echo "#{script_name} is finished at $(date +%Y%m%d%H%M%S)" >> "#{jobs_dir}/finished_jobs"

exit $EXITSTATUS
