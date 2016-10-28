module CagnutGatk
  class PrintReads
    extend Forwardable

    def_delegators :'Cagnut::Configuration.base', :sample_name, :jobs_dir, :target_flanks_file,
                   :ref_fasta, :prefix_name, :dodebug, :java_path
    def_delegators :'CagnutGatk.config', :print_reads_params

    def initialize opts = {}
      @job_name = "#{prefix_name}_PrintReads_#{sample_name}"
      @input = opts[:input].nil? ? "#{opts[:dirs][:input]}/#{sample_name}_realn.bam" : opts[:input]
      @output = "#{opts[:dirs][:output]}/#{output_file}"
      @bqsr_file = "#{opts[:dirs][:contrast]}/#{replace_filename('_recal.csv')}"
    end

    def file_basename
      @basename ||= File.basename @input
    end

    def replace_filename target
      file_basename.gsub '_realn.bam', target
    end

    def output_file
      output = replace_filename '_recal.bam'
      return output unless output == file_basename
      abort 'Input file is not correctly'
    end

    def run previous_job_id = nil
      puts "Submitting PrintReads #{sample_name}"
      script_name = generate_script
      ::Cagnut::JobManage.submit script_name, @job_name, cluster_options(previous_job_id)
      [@job_name, @output]
    end

    def cluster_options previous_job_id = nil
      {
        previous_job_id: previous_job_id,
        adjust_memory: ['h_vmem=6G'],
        tools: ['gatk', 'print_reads']
      }
    end

    def generate_script
      script_name = 'gatk_print_reads'
      file = File.join jobs_dir, "#{script_name}.sh"
      path = File.expand_path '../templates/print_reads.sh', __FILE__
      template = Tilt.new path
      File.open(file, 'w') do |f|
        f.puts template.render Object.new, job_params(script_name)
      end
      File.chmod(0700, file)
      script_name
    end

    def print_reads_options
      ary = print_reads_params['params'].dup
      ary << "-T PrintReads"
      ary << "-R #{ref_fasta}"
      ary << "-I #{@input}"
      ary << "-o #{@output}"
      ary << "-BQSR #{@bqsr_file}"
      ary << "-L #{target_flanks_file}" if target_flanks_file
      ary.uniq
    end

    def modified_java_array
      array = print_reads_params['java'].dup
      array.unshift(java_path).uniq
    end

    def params_combination
      {
        'java' => modified_java_array,
        'params' => print_reads_options
      }
    end

    def job_params script_name
      {
        script_name: script_name,
        jobs_dir: jobs_dir,
        output: @output,
        bqsr_file: @bqsr_file,
        print_reads_params: params_combination,
        run_local: ::Cagnut::JobManage.run_local,
      }
    end
  end
end
