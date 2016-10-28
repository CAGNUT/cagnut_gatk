#!/bin/bash

cd "#{jobs_dir}/../"
echo "#{script_name} is starting at $(date +%Y%m%d%H%M%S)" >> "#{jobs_dir}/finished_jobs"
rm core.* 2> /dev/null

# Check BAM EOF
BAM_28=$(tail -c 28 #{input}|xxd -p)
if [ "#{magic28}" != "$BAM_28" ]
then
  echo "Error with BAM EOF"
  exit 100
fi

#{base_recalibrator_params['java'].join("\s")} \\
  #{base_recalibrator_params['params'].join(" \\\n  ")} \\
  #{run_local}

EXITSTATUS=$?

#force error when missing recalFile. Would prevent continutation of pipeline
if [ ! -s #{output} ]
then
 echo "Missing #{output}"
 exit 100
fi

echo "#{script_name} is finished at $(date +%Y%m%d%H%M%S)" >> "#{jobs_dir}/finished_jobs"

exit $EXITSTATUS
