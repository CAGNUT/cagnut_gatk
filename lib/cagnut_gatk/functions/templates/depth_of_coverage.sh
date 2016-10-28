#!/bin/bash

cd "#{jobs_dir}/../"
echo "#{script_name} is starting at $(date +%Y%m%d%H%M%S)" >> "#{jobs_dir}/finished_jobs"

#{depth_of_coverage_params['java'].join("\s")} \\
  #{depth_of_coverage_params['params'].join(" \\\n  ")} \\
  #{run_local}

EXITSTATUS=$?

if [ ! -e "#{output}.sample_statistics" ]
then
  echo "Missing output: #{output}"
  exit 100
fi
echo "#{script_name} is finished at $(date +%Y%m%d%H%M%S)" >> "#{jobs_dir}/finished_jobs"

exit $EXITSTATUS
