module CagnutGatk
  class VariantFiltration
    extend Forwardable

    def_delegators :'Cagnut::Configuration.base', :sample_name, :jobs_dir, :prefix_name,
                   :ref_fasta, :dodebug, :java_path
    def_delegators :'CagnutGatk.config', :variant_filtration_params

    def initialize opts = {}
      @order = sprintf '%02i', opts[:order]
      @input = opts[:input].nil? ? "#{opts[:dirs][:input]}/#{sample_name}.vcf" : opts[:input]
      @job_name = "#{prefix_name}_snpFiltr_#{sample_name}"
      @output = "#{opts[:dirs][:output]}/#{sample_name}_filtered.vcf"
    end

    def run previous_job_id = nil
      puts "Submitting #{sample_name} Jobs: variant (SNPs, INDELs) -filtration"
      script_name = generate_script
      ::Cagnut::JobManage.submit script_name, @job_name, cluster_options(previous_job_id)
      [@job_name, @output]
    end

    def cluster_options previous_job_id = nil
      {
        previous_job_id: previous_job_id,
        adjust_memory: ['h_stack=256M', 'h_vmem=10G'],
        tools: ['gatk', 'variant_filtration']
      }
    end

    def params_combination
      @params_combination_hash ||= {
        'java' => modified_java_array,
        'params' => variant_filtration_options
      }
    end

    def variant_filtration_options
      array = variant_filtration_params['params'].dup
      array << "-T VariantFiltration"
      array << "-R #{ref_fasta}"
      array << "--variant:VCF #{@input}"
      array << "-o #{@output}"
      array.uniq
    end

    def modified_java_array
      array = variant_filtration_params['java'].dup
      array.unshift(java_path).uniq
    end

    def generate_script
      script_name = "#{@order}_gatk_variant_filtration"
      file = File.join jobs_dir, "#{script_name}.sh"
      File.open(file, 'w') do |f|
        f.puts <<-BASH.strip_heredoc
          #!/bin/bash

          cd "#{jobs_dir}/../"
          echo "#{script_name} is starting at $(date +%Y%m%d%H%M%S)" >> "#{jobs_dir}/finished_jobs"
          if [ ! -s "#{@input}.idx" ]; then
           echo "Incomplete VCF:" #{@input}
           exit 100
          fi

          #{params_combination['java'].join("\s")} \\
            #{params_combination['params'].join(" \\\n            ")} \\
            #{::Cagnut::JobManage.run_local}

          EXITSTATUS=$?

          #if [ ! -s "#{@output}" ]; then exit 100;fi;

          if [ ! -s "#{@output}.idx" ]
          then
            echo "vcf incomplete!"
            exit 100;
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
