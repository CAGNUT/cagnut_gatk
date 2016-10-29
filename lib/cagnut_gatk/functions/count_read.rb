module CagnutGatk
  class CountRead
    extend Forwardable

    def_delegators :'Cagnut::Configuration.base', :sample_name, :jobs_dir, :java_path,
                   :ref_fasta, :prefix_name, :dodebug
    def_delegators :'CagnutGatk.config', :count_reads_params

    def initialize opts = {}
      @order = sprintf '%02i', opts[:order]
      @target = opts[:target]
      @suffix = @target.nil? ? 'genome.readct' : 'target.readct'
      @input = opts[:input].nil? ? "#{opts[:dirs][:input]}/#{sample_name}_markdup.bam" : opts[:input]
      @output = "#{opts[:dirs][:output]}/#{sample_name}_markdup_#{@suffix}"
      @job_name = "#{prefix_name}_countRead_#{sample_name}_#{@suffix}"
    end

    def run previous_job_id = nil
      puts "Submitting countRead #{@suffix}"
      script_name = generate_script
      ::Cagnut::JobManage.submit script_name, @job_name, cluster_options(previous_job_id)
      @job_name
    end

    def cluster_options previous_job_id = nil
      {
        previous_job_id: previous_job_id,
        var_env: [ref_fasta],
        adjust_memory: ['h_vmem=5G'],
        tools: ['gatk', 'count_reads']
      }
    end

    def generate_script
      script_name = "#{@order}_gatk_count_reads_#{@suffix}"
      file = File.join jobs_dir, "#{script_name}.sh"
      path = File.expand_path '../templates/count_read.sh', __FILE__
      template = Tilt.new path
      File.open(file, 'w') do |f|
        f.puts template.render Object.new, job_params(script_name)
      end
      File.chmod(0700, file)
      script_name
    end

    def count_reads_options
      array = count_reads_params['params'].dup
      array << "-T CountReads"
      array << "-R #{ref_fasta}"
      array << "-I #{@input} > #{@output}"
      array << "-L #{@target}" if @target
      array.uniq
    end

    def modified_java_array
      array = count_reads_params['java'].dup
      array.unshift(java_path).uniq
    end

    def params_combination
      {
        'java' => modified_java_array,
        'params' => count_reads_options
      }
    end

    def job_params script_name
      {
        jobs_dir: jobs_dir,
        script_name: script_name,
        output: @output,
        count_reads_params: params_combination,
        run_local: ::Cagnut::JobManage.run_local
      }
    end
  end
end
