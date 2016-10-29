module CagnutGatk
  class BaseRecalibrator
    extend Forwardable

    def_delegators :'Cagnut::Configuration.base', :sample_name, :jobs_dir, :prefix_name,
                   :ref_fasta, :snpdb, :target_flanks_file, :dodebug,
                   :magic28, :java_path
    def_delegators :'CagnutGatk.config', :base_recalibrator_params

    def initialize opts = {}
      @order = sprintf '%02i', opts[:order]
      @csv_dir = opts[:dirs][:output]
      @has_bqsr_file = opts[:has_bqsr_file]
      @input = opts[:file_name].nil? ? "#{opts[:dirs][:input]}/#{sample_name}_realn.bam" : opts[:input]
      setup_output_and_bqsr_file
    end

    def setup_output_and_bqsr_file
      file_name = File.basename @input
      if @has_bqsr_file
        output = file_name.gsub '_realn.bam', '_recal_post.csv'
        bqsr_file = file_name.gsub '_realn.bam', '_recal.csv'
      else
        output = file_name.gsub '_realn.bam', '_recal.csv'
      end
      @output = "#{@csv_dir}/#{output}"
      @bqsr_file = "#{@csv_dir}/#{bqsr_file}" if @has_bqsr_file
    end

    def run previous_job_id = nil
      message = @has_bqsr_file ? 'with BQSR' : ''
      puts "Submitting BaseRecalibrator #{sample_name} #{message}"
      script_name = generate_script
      job_name = "#{prefix_name}_#{script_name}"
      ::Cagnut::JobManage.submit script_name, job_name, cluster_options(previous_job_id)
      job_name
    end

    def cluster_options previous_job_id = nil
      core_num = 6
      {
        previous_job_id: previous_job_id,
        var_env: [core_num],
        adjust_memory: ["h_vmem=adjustWorkingMem 7G #{core_num}"],
        parallel_env: [core_num],
        tools: ['gatk', 'base_recalibrator']
      }
    end

    def generate_script
      script_name = @has_bqsr_file ? "#{@order}_gatk_base_recalibrator_post" : "#{@order}_gatk_base_recalibrator"
      file = File.join jobs_dir, "#{script_name}.sh"
      path = File.expand_path "../templates/base_recalibrator.sh", __FILE__
      template = Tilt.new path
      File.open(file, 'w') do |f|
        f.puts template.render Object.new, job_params(script_name)
      end
      File.chmod(0700, file)
      script_name
    end

    def base_recalibrator_options
      dtag = snpdb.nil? ? "--run_without_dbsnp_potentially_ruining_quality" : "-knownSites #{snpdb}"
      array = base_recalibrator_params['params'].dup
      array << "-T BaseRecalibrator"
      array << "-R #{ref_fasta}"
      array << "-I #{@input}"
      array << "-o #{@output}"
      array << "#{dtag}"
      array << "-BQSR #{@bqsr_file}" if @has_bqsr_file
      array << "-L #{target_flanks_file}" if target_flanks_file
      array.uniq
    end

    def modified_java_array
      array = base_recalibrator_params['java'].dup
      array.unshift(java_path).uniq
    end

    def params_combination
      {
        'java' => modified_java_array,
        'params' => base_recalibrator_options
      }
    end

    def job_params script_name
      {
        jobs_dir: jobs_dir,
        script_name: script_name,
        magic28: magic28,
        input: @input,
        output: @output,
        base_recalibrator_params: params_combination,
        run_local: ::Cagnut::JobManage.run_local
      }
    end
  end
end
