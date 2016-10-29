module CagnutGatk
  class DepthOfCoverage
    extend Forwardable

    def_delegators :'Cagnut::Configuration.base', :sample_name, :jobs_dir, :java_path,
                   :ref_fasta, :prefix_name, :dodebug
    def_delegators :'CagnutGatk.config', :depth_of_coverage_params

    def initialize opts = {}
      @order = sprintf '%02i', opts[:order]
      @suffix = opts[:suffix]
      @target_file = opts[:target]
      @job_name = "#{prefix_name}_#{sample_name}_#{@suffix}_depthofcoverage"
      @input = opts[:input].nil? ? "#{opts[:dirs][:input]}/#{sample_name}_recal.bam" : opts[:input]
      @output = "#{opts[:dirs][:output]}/#{sample_name}_#{@suffix}_depthofcoverage"
    end

    def run previous_job_id = nil
      puts "Submitting #{sample_name} #{@suffix} depth of coverage Jobs"
      script_name = generate_script
      ::Cagnut::JobManage.submit script_name, @job_name, cluster_options(previous_job_id)
      [@job_name, @output]
    end

    def cluster_options previous_job_id = nil
      core_num = 6
      {
        previous_job_id: previous_job_id,
        var_env: [core_num],
        adjust_memory: ['h_stack=256M', 'h_vmem=8G'],
        parallel_env: [core_num],
        tools: ['gatk', 'depth_of_coverage']
      }
    end

    def generate_script
      file_name = "#{@order}_gatk_depth_of_coverage_#{@suffix}"
      file = File.join jobs_dir, "#{file_name}.sh"
      path = File.expand_path '../templates/depth_of_coverage.sh', __FILE__
      template = Tilt.new path
      File.open(file, 'w') do |f|
        f.puts template.render Object.new, job_params(file_name)
      end
      File.chmod(0700, file)
      file_name
    end

    def depth_of_coverage_options
      target = @target_file.blank? ? '-omitIntervals' : "-L #{@target_file}"
      array = depth_of_coverage_params['params'].dup
      array << "-T DepthOfCoverage"
      array << "-R #{ref_fasta}"
      array << "-I #{@input}"
      array << "-o #{@output}"
      array << target
      array.uniq
    end

    def modified_java_array
      array = depth_of_coverage_params['java'].dup
      array.unshift(java_path).uniq
    end

    def params_combination_hash
      {
        'java' => modified_java_array,
        'params' => depth_of_coverage_options
      }
    end

    def job_params script_name
      {
        jobs_dir: jobs_dir,
        script_name: script_name,
        output: @output,
        depth_of_coverage_params: params_combination_hash,
        run_local: ::Cagnut::JobManage.run_local
      }
    end
  end
end
