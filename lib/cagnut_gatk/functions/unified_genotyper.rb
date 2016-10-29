module CagnutGatk
  class UnifiedGenotyper
    extend Forwardable

    def_delegators :'Cagnut::Configuration.base', :sample_name, :jobs_dir, :dodebug,
                   :ref_fasta, :snpdb, :target, :prefix_name, :java_path
    def_delegators :'CagnutGatk.config', :unified_genotyper_params

    def initialize opts = {}
      @order = sprintf '%02i', opts[:order]
      @input = opts[:input].nil? ? "#{opts[:dirs][:input]}/#{sample_name}_recal.bam" : opts[:input]
      @output = "#{opts[:dirs][:output]}/#{sample_name}.vcf"
      @job_name = "#{prefix_name}_snpcal_#{sample_name}"
    end

    def run previous_job_id = nil
      puts "Submitting #{sample_name} Jobs: variant (SNPs, INDELs) -call "
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
        tools: ['gatk', 'unified_genotyper']
      }
    end

    def unified_genotyper_options
      array = unified_genotyper_params['params'].dup
      array << "-T UnifiedGenotyper"
      array << "-R #{ref_fasta}"
      array << "-I #{@input}"
      array << "-o #{@output}"
      array << "-D #{snpdb}" if snpdb
      array << "-L #{target}" if target
      array.uniq
    end

    def modified_java_array
      array = unified_genotyper_params['java'].dup
      array.unshift(java_path).uniq
    end

    def params_combination
      @params_combination_hash ||= {
        'java' => modified_java_array,
        'params' => unified_genotyper_options
      }
    end

    def generate_script
      script_name = "#{@order}_gatk_unified_genotyper"
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

          if [ ! -s "#{@output}.idx" ]
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
