module CagnutGatk
  class Util
    attr_accessor :gatk, :config

    def initialize config
      @config = config
      @gatk = CagnutGatk::Base.new
    end

    def count_read dirs, order=1, previous_job_id=nil, filename=nil
      count_read_params(filename).each do |option|
        gatk.count_read dirs, order, previous_job_id, option
      end
      order+1
    end

    def recal dirs, order=1, previous_job_id=nil, filename = nil
      # if (@config['cagnut']['ref_fasta'].scan 'hg').empty?
      #   # filename = "s_#{@config['line']}_merged_markdup.bam"
      #   filename = "#{line}_realn.bam"
      # else
      #   previous_job_id, target_interval = realigner_target_creator previous_job_id, filename
      #   previous_job_id, filename = indel_realigner previous_job_id, filename, target_interval
      # end

      previous_job_id, interval_list, order = realigner_target_creator dirs, order, previous_job_id, filename
      previous_job_id, filename, order = indel_realigner dirs, order, previous_job_id, filename, interval_list
      previous_job_id, order = base_recalibrator dirs, order, previous_job_id, filename
      previous_job_id, filename = print_reads dirs, order, previous_job_id, filename
      [previous_job_id, previous_job_id, order+1]
    end

    def realigner_target_creator dirs, order=1, previous_job_id=nil, filename=nil
      job_name, interval_list = @gatk.realigner_target_creator dirs, order, previous_job_id, filename
      [job_name, interval_list, order+1]
    end

    def indel_realigner dirs, order=1, previous_job_id=nil, filename=nil, interval_list=nil
      job_name, filename = @gatk.indel_realigner dirs, order, previous_job_id, filename, interval_list
      [job_name, filename, order+1]
    end

    def base_recalibrator dirs, order=1, previous_job_id=nil, filename=nil
      before_and_after_generated_bqsr_file.each do |option|
        previous_job_id = @gatk.base_recalibrator dirs, order, previous_job_id, filename, option
      end
      [previous_job_id, order+1]
    end

    def analyze_covariates dirs, order=1, previous_job_id=nil, filename=nil
      job_name = @gatk.analyze_covariates dirs, order, previous_job_id, filename
      [job_name, order+1]
    end

    def print_reads dirs, order=1, previous_job_id=nil, file_name=nil
      job_name, filename = @gatk.print_reads dirs, order, previous_job_id, file_name
      [job_name, filename, order+1]
    end

    def depth_of_coverage dirs, order=1, previous_job_id=nil, filename=nil
      depth_of_coverage_params.each do |option|
        @gatk.depth_of_coverage dirs, order, previous_job_id, filename, option
      end
      order+1
    end

    def haplotype_caller dirs, order=1, previous_job_id=nil, file_name=nil
      job_name, filename = @gatk.haplotype_caller dirs, order, previous_job_id, file_name
      [job_name, filename, order+1]
    end

    def unified_genotyper dirs, order=1, previous_job_id=nil, file_name=nil
      job_name, filename = @gatk.unified_genotyper dirs, order, previous_job_id, file_name
      [job_name, filename, order+1]
    end

    def snpcal dirs, order=1, previous_job_id=nil, filename = nil
      previous_job_id, filename, order = variant_filtration dirs, order, previous_job_id, filename
      variant_eval dirs, order, previous_job_id, filename
    end

    def variant_filtration dirs, order=1, previous_job_id=nil, filename=nil
      job_name, filename = gatk.variant_filtration dirs, order, previous_job_id, filename
      [job_name, filename, order+1]
    end

    def variant_eval dirs, order=1, previous_job_id=nil, filename=nil
      job_name, filename = gatk.variant_eval dirs, order, previous_job_id, filename
      [job_name, filename, order+1]
    end

    private

    def before_and_after_generated_bqsr_file
      [{ has_bqsr_file: false }, { has_bqsr_file: true }]
    end

    def count_read_params filename
      ary = [{ input: filename }]
      if @config['refs']['targets_file']
        ary <<
          { input: filename, target: @config['refs']['targets_file'] }
      end
      ary
    end

    def depth_of_coverage_params
      ary = [{ suffix: 'genome' }]
      if @config['refs']['targets_file']
        ary << { suffix: 'target', target: @config['refs']['targets_file'] }
      end
      if @config['refs']['target_flanks_file']
        ary << { suffix: 'flank', target: @config['refs']['target_flanks_file'] }
      end
      ary
    end
  end
end
