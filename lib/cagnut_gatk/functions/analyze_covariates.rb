module CagnutGatk
  class AnalyzeCovariates
    extend Forwardable

    def_delegators :'Cagnut::Configuration.base', :sample_name, :jobs_dir, :prefix_name,
                   :ref_fasta, :dodebug, :java_path, :magic28
    def_delegators :'CagnutGatk.config', :analyze_covariates_params

    def initialize opts = {}
      @job_name = "#{prefix_name}_AnalyzeCovariates_#{sample_name}"
      @input = opts[:input].nil? ? "#{opts[:dirs][:input]}/#{sample_name}_realn.bam" : opts[:input]
      @recal_csv = "#{opts[:dirs][:contrast]}/#{replace_filename('_recal.csv')}"
      @recal_bqsr_csv = "#{opts[:dirs][:contrast]}/#{replace_filename('_recal_post.csv')}"
      @output = "#{opts[:dirs][:output]}/#{output_file}"
    end

    def file_basename
      @basename ||= File.basename @input
    end

    def replace_filename target_name
      file_basename.gsub '_realn.bam', target_name
    end

    def output_file
      output = replace_filename '_recalibration_plots.pdf'
      return output unless output == file_basename
      abort 'Input file is not correctly'
    end

    def run previous_job_id = nil
      puts "Submitting AnalyzeCovariates #{sample_name}"
      script_name = generate_script
      ::Cagnut::JobManage.submit script_name, @job_name, cluster_options(previous_job_id)
      @job_name
    end

    def cluster_options previous_job_id = nil
      core_num = 6
      {
        previous_job_id: previous_job_id,
        var_env: ["#{core_num}"],
        adjust_memory: ["h_vmem=adjustWorkingMem 7G #{core_num}"],
        tools: ['gatk', 'analyze_covariates']
      }
    end

    def generate_script
      script_name = 'gatk_analyze_covariates'
      file = File.join jobs_dir, "#{script_name}.sh"
      path = File.expand_path '../templates/analyze_covariates.sh', __FILE__
      template = Tilt.new path
      File.open(file, 'w') do |f|
        f.puts template.render Object.new, job_params(script_name)
      end
      File.chmod(0700, file)
      script_name
    end

    def params_combination
      {
        'java' => modified_java_array,
        'params' => analyze_covariates_options
      }
    end

    def analyze_covariates_options
      array = analyze_covariates_params['params'].dup
      array << "-T AnalyzeCovariates"
      array << "-R #{ref_fasta}"
      array << "-before #{@recal_csv}"
      array << "-after #{@recal_bqsr_csv}"
      array << "-plots #{@output}"
      array.uniq
    end

    def modified_java_array
      array = analyze_covariates_params['java'].dup
      array.unshift(java_path).uniq
    end

    def job_params script_name
      {
        jobs_dir: jobs_dir,
        script_name: script_name,
        after: @after,
        output: @output,
        analyze_covariates_params: params_combination,
        run_local: "#{::Cagnut::JobManage.run_local}"
      }
    end
  end
end
