module CagnutGatk
  class VariantEval
    extend Forwardable

    def_delegators :'Cagnut::Configuration.base', :sample_name, :jobs_dir, :java_path,
                   :ref_fasta, :snpdb, :target, :prefix_name, :dodebug
    def_delegators :'CagnutGatk.config', :variant_eval_params

    def initialize opts = {}
      @order = sprintf '%02i', opts[:order]
      @vcf_dir = opts[:dirs][:output]
      @input = opts[:input].nil? ? "#{opts[:dirs][:input]}/#{sample_name}_filtered.vcf" : opts[:input]
      @output = "#{@vcf_dir}/#{sample_name}.eval"
      @job_name = "#{prefix_name}_snpEval_#{sample_name}"
    end

    def run previous_job_id = nil
      return unless snpdb
      puts "Submitting #{sample_name} Jobs: variant (SNPs, INDELs) -evaluation "
      script_name = generate_script
      ::Cagnut::JobManage.submit script_name, @job_name, cluster_options(previous_job_id)
      @job_name
    end

    def cluster_options previous_job_id = nil
      {
        previous_job_id: previous_job_id,
        adjust_memory: ['h_stack=256M', 'h_vmem=8G'],
        tools: ['gatk', 'variant_eval']
      }
    end

    def variant_eval_options
      array = variant_eval_params['params'].dup
      array << "-T VariantEval"
      array << "-R #{ref_fasta}"
      array << "--dbsnp #{snpdb}"
      array << "-o #{@output}"
      array << "--eval:$EVALNAME #{@input}"
      array << "-L #{target}" if target
      array.uniq
    end

    def modified_java_array
      array = variant_eval_params['java'].dup
      array.unshift(java_path).uniq
    end

    def params_combination
      @params_combination_hash ||= {
        'java' => modified_java_array,
        'params' => variant_eval_options
      }
    end

    def generate_script
      script_name = "#{@order}_gatk_variant_eval"
      file = File.join jobs_dir, "#{script_name}.sh"
      ltag = target.nil? ? '' : "-L #{target}"
      File.open(file, 'w') do |f|
        f.puts <<-BASH.strip_heredoc
          #!/bin/bash

          cd "#{jobs_dir}/../"
          echo "#{script_name} is starting at $(date +%Y%m%d%H%M%S)" >> "#{jobs_dir}/finished_jobs"
          EVALNAME=$(basename #{@vcf_dir}/#{sample_name})

          #{params_combination['java'].join("\s")} \\
            #{params_combination['params'].join(" \\\n            ")} \\
            #{::Cagnut::JobManage.run_local}

          EXITSTATUS=$?

          if [ ! -s "#{@output}" ]
          then
            echo "Missing #{@output}"
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
