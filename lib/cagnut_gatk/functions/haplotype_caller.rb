module CagnutGatk
  class HaplotypeCaller
    extend Forwardable

    def_delegators :'Cagnut::Configuration.base', :sample_name, :jobs_dir, :java_path,
                   :ref_fasta, :target, :prefix_name, :dodebug, :target_flanks_file
    def_delegators :'CagnutGatk.config', :haplotype_caller_params

    def initialize opts = {}
      @input = opts[:input].nil? ? "#{opts[:dirs][:input]}/#{sample_name}_recal.bam" : opts[:input]
      @output = "#{opts[:dirs][:output]}/#{sample_name}.vcf"
      @job_name = "#{prefix_name}_haplotype_caller_#{sample_name}"
    end

    def run previous_job_id = nil
      puts "Submitting HaplotypeCaller #{sample_name} "
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
        var_env: [core_num, target],
        adjust_memory: ["h_stack=#{job_mem1}", "h_vmem=#{job_mem2}"],
        parallel_env: [core_num],
        tools: ['gatk', 'haplotype_caller']
      }
    end

    def haplotype_caller_options
      array = haplotype_caller_params['params'].dup
      array << "-T HaplotypeCaller"
      array << "-R #{ref_fasta}"
      array << "-I #{@input}"
      array << "-o #{@output}"
      array << "-L #{target_flanks_file}" if target_flanks_file
      array.uniq
    end

    def modified_java_array
      array = haplotype_caller_params['java'].dup
      array.unshift(java_path).uniq
    end

    def params_combination
      @params_combination_hash ||= {
        'java' => modified_java_array,
        'params' => haplotype_caller_options
      }
    end

    def generate_script
      script_name = 'gatk_haplotype_caller'
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

          if [ ! -s "#{@output}" ]
          then
            echo "vcf incomplete!"
            exit 100;
          fi

          if [ $EXITSTATUS -ne 0 ];then exit $EXITSTATUS;fi
          echo "#{script_name} is finished at $(date +%Y%m%d%H%M%S)" >> "#{jobs_dir}/finished_jobs"

        BASH
      end
      File.chmod(0700, file)
      script_name
    end
  end
end
