module CagnutGatk
  class RealignerTargetCreator
    extend Forwardable

    def_delegators :'Cagnut::Configuration.base', :sample_name, :jobs_dir, :dodebug,
                   :ref_fasta, :snpdb, :target_flanks_file, :prefix_name,
                   :java_path
    def_delegators :'CagnutGatk.config', :realigner_target_creator_params

    def initialize opts = {}
      @job_name = "#{prefix_name}_realignTargetCreator_#{sample_name}"
      @input = opts[:input].nil? ? "#{opts[:dirs][:input]}/#{sample_name}_markdup.bam" : opts[:input]
      @output = "#{opts[:dirs][:output]}/#{sample_name}_markdup.interval_list"
    end

    def run previous_job_id = nil
      puts "Submitting realigner_target_creator #{sample_name}"
      script_name = generate_script
      ::Cagnut::JobManage.submit script_name, @job_name, cluster_options(previous_job_id)
      [@job_name, @output]
    end

    def cluster_options previous_job_id = nil
      core_num = 6
      job_mem1 = "adjustWorkingMem 256M #{core_num}"
      job_mem2 = "adjustWorkingMem 10G #{core_num}"
      {
        previous_job_id: previous_job_id,
        var_env: [core_num],
        adjust_memory: ["h_stack=#{job_mem1}", "h_vmem=#{job_mem2}"],
        parallel_env: [core_num],
        tools: ['gatk', 'realigner_target_creator']
      }
    end

    def realigner_target_creator_options
      array = realigner_target_creator_params['params'].dup
      array << "-T RealignerTargetCreator"
      array << "-R #{ref_fasta}"
      array << "--known #{snpdb}"
      array << "-I #{@input}"
      array << "-o #{@output}"
      array << "-L #{target_flanks_file}" if target_flanks_file
      array.uniq!
      array.uniq
    end

    def modified_java_array
      array = realigner_target_creator_params['java'].dup
      array.unshift(java_path).uniq
    end

    def params_combination
      @params_combination_hash ||= {
        'java' => modified_java_array,
        'params' => realigner_target_creator_options
      }
    end

    def generate_script
      script_name = 'gatk_realigner_target_creator'
      file = File.join jobs_dir, "#{script_name}.sh"
      File.open(file, 'w') do |f|
        f.puts <<-BASH.strip_heredoc
          #!/bin/bash

          cd "#{jobs_dir}/../"
          echo "#{script_name} is starting at $(date +%Y%m%d%H%M%S)" >> "#{jobs_dir}/finished_jobs"

          #{params_combination['java'].join("\s")} \\
            #{params_combination['params'].join(" \\\n            ")} \\
            #{::Cagnut::JobManage.run_local}

          EXITSTATUS=$?

          #force error when missing output
          if [ ! -s "#{@output}" ]
          then
            echo "Missing indel_calls #{@output}, can not continue"
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
