module CagnutGatk
  class Util
    attr_accessor :gatk, :config

    def initialize config
      @config = config
      @gatk = CagnutGatk::Base.new
    end

    def count_read dirs, previous_job_id, filename
      count_read_params(filename).each do |option|
        gatk.count_read dirs, previous_job_id, option
      end
    end

    def recal dirs, previous_job_id, filename = nil
      # if (@config['cagnut']['ref_fasta'].scan 'hg').empty?
      #   # filename = "s_#{@config['line']}_merged_markdup.bam"
      #   filename = "#{line}_realn.bam"
      # else
      #   previous_job_id, target_interval = realigner_target_creator previous_job_id, filename
      #   previous_job_id, filename = indel_realigner previous_job_id, filename, target_interval
      # end
      previous_job_id, interval_list = realigner_target_creator dirs, previous_job_id, filename
      previous_job_id, filename = indel_realigner dirs, previous_job_id, filename, interval_list
      previous_job_id = base_recalibrator dirs, previous_job_id, filename
      print_reads dirs, previous_job_id, filename
    end

    def realigner_target_creator dirs, previous_job_id, filename = nil
      @gatk.realigner_target_creator dirs, previous_job_id, filename
    end

    def indel_realigner dirs, previous_job_id, filename, interval_list
      @gatk.indel_realigner dirs, previous_job_id, filename, interval_list
    end

    def base_recalibrator dirs, previous_job_id, filename
      before_and_after_generated_bqsr_file.each do |option|
        previous_job_id = @gatk.base_recalibrator dirs, previous_job_id, filename, option
      end
      previous_job_id
    end

    def analyze_covariates dirs, previous_job_id, filename
      @gatk.analyze_covariates dirs, previous_job_id, filename
    end

    def print_reads dirs, previous_job_id, file_name
      @gatk.print_reads dirs, previous_job_id, file_name
    end

    def depth_of_coverage dirs, previous_job_id, filename
      depth_of_coverage_params.each do |option|
        @gatk.depth_of_coverage dirs, previous_job_id, filename, option
      end
    end

    def haplotype_caller dirs, previous_job_id, file_name
      @gatk.haplotype_caller dirs, previous_job_id, file_name
    end

    def unified_genotyper dirs, previous_job_id, file_name
      @gatk.unified_genotyper dirs, previous_job_id, file_name
    end

    def snpcal dirs, previous_job_id, filename = nil
      previous_job_id, filename = gatk.variant_filtration dirs, previous_job_id, filename
      gatk.variant_eval dirs, previous_job_id, filename
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
