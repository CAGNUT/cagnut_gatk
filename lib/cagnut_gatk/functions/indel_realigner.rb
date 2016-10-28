module CagnutGatk
  class IndelRealigner
    extend Forwardable

    def_delegators :'Cagnut::Configuration.base', :sample_name, :jobs_dir, :dodebug,
                   :ref_fasta, :target_flanks_file, :dbsnp_ref_indels,
                   :magic28, :prefix_name, :java_path
    def_delegators :'CagnutGatk.config', :indel_realigner_params

    def initialize opts = {}
      @job_name = "#{prefix_name}_indelRealigner_#{sample_name}"
      @interval_list = opts[:interval_list]
      @input = opts[:input].nil? ? "#{opts[:dirs][:input]}/#{sample_name}_markdup.bam" : opts[:input]
      @output = "#{opts[:dirs][:output]}/#{sample_name}_realn.bam"
    end

    def run previous_job_id = nil
      puts "Submitting indel_realigner #{sample_name}"
      script_name = generate_script
      ::Cagnut::JobManage.submit script_name, @job_name, cluster_options(previous_job_id)
      [@job_name, @output]
    end

    def cluster_options previous_job_id = nil
      {
        previous_job_id: previous_job_id,
        adjust_memory: ['h_vmem=8G'],
        tools: ['gatk', 'indel_realigner']
      }
    end

    def indel_realigner_options
      array = indel_realigner_params['params'].dup
      array << "-T IndelRealigner"
      array << "-R #{ref_fasta}"
      array << "-targetIntervals #{@interval_list}"
      array << "-I #{@input}"
      array << "-o #{@output}"
      array << "-known #{dbsnp_ref_indels}" if dbsnp_ref_indels
      array.uniq!
      array.uniq
    end

    def modified_java_array
      array = indel_realigner_params['java'].dup
      array.unshift(java_path).uniq
    end

    def params_combination
      @params_combination_hash ||= {
        'java' => modified_java_array,
        'params' => indel_realigner_options
      }
    end

    def generate_script
      script_name = 'gatk_indel_realigner'
      file = File.join jobs_dir, "#{script_name}.sh"
      File.open(file, 'w') do |f|
        f.puts <<-BASH.strip_heredoc
          #!/bin/bash

          cd "#{jobs_dir}/../"
          echo "#{script_name} is starting at $(date +%Y%m%d%H%M%S)" >> "#{jobs_dir}/finished_jobs"
          # Check for intervals file
          if [ ! -s "#{@interval_list}" ];then
            echo "Error: Missing interval file: "#{@interval_list}" from realignTargetCreator_#{sample_name}"
            exit 100
          fi

          #{params_combination['java'].join("\s")} \\
            #{params_combination['params'].join(" \\\n            ")} \\
            #{::Cagnut::JobManage.run_local}

          EXITSTATUS=$?

          #force error when missing @output
          if [ ! -s "#{@output}" ]
          then
            echo "Missing @output BAM #{@output}"
            exit 100
          fi

          # Check BAM EOF
          BAM_28=$(tail -c 28 #{@output}|xxd -p)
          if [ "#{magic28}" != "$BAM_28" ]
          then
            echo "Error with BAM EOF" 1>&2
            exit 100
          fi
          echo "#{script_name} is finished at $(date +%Y%m%d%H%M%S)" >> "#{jobs_dir}/finished_jobs"

          exit $EXITSTATUS
        BASH
      end
      File.chmod(0700, file)
      script_name
    end
  end
end
