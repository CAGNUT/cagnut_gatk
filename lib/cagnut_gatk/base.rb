require 'cagnut_gatk/functions/count_read'
require 'cagnut_gatk/functions/realigner_target_creator'
require 'cagnut_gatk/functions/indel_realigner'
require 'cagnut_gatk/functions/base_recalibrator'
require 'cagnut_gatk/functions/analyze_covariates'
require 'cagnut_gatk/functions/print_reads'
require 'cagnut_gatk/functions/depth_of_coverage'
require 'cagnut_gatk/functions/unified_genotyper'
require 'cagnut_gatk/functions/haplotype_caller'
require 'cagnut_gatk/functions/variant_filtration'
require 'cagnut_gatk/functions/variant_eval'

module CagnutGatk
  class Base

    def count_read dirs, order, previous_job_id, opts = {}
      opts = { dirs: dirs, order: order }.merge opts
      count_read = CagnutGatk::CountRead.new opts
      count_read.run previous_job_id
    end

    def realigner_target_creator dirs, order, previous_job_id, input = nil
      opts = { input: input, dirs: dirs, order: order }
      realigner_target_creator = CagnutGatk::RealignerTargetCreator.new opts
      realigner_target_creator.run previous_job_id
    end

    def indel_realigner dirs, order, previous_job_id, input, interval_list
      opts = { input: input, interval_list: interval_list, dirs: dirs, order: order }
      indel_realigner = CagnutGatk::IndelRealigner.new opts
      indel_realigner.run previous_job_id
    end

    def base_recalibrator dirs, order, previous_job_id, input, opts
      opts = { input: input, dirs: dirs, order: order }.merge opts
      base_recalibrator = CagnutGatk::BaseRecalibrator.new opts
      base_recalibrator.run previous_job_id
    end

    def analyze_covariates dirs, order, previous_job_id, input
      opts = { input: input, dirs: dirs, order: order }
      analyze_covariates = CagnutGatk::AnalyzeCovariates.new opts
      analyze_covariates.run previous_job_id
    end

    def print_reads dirs, order, previous_job_id, input
      opts = { input: input, dirs: dirs, order: order}
      print_reads = CagnutGatk::PrintReads.new opts
      print_reads.run previous_job_id
    end

    def depth_of_coverage dirs, order, previous_job_id, input, opts
      opts = { input: input, dirs: dirs, order: order }.merge opts
      depth_of_coverage = CagnutGatk::DepthOfCoverage.new opts
      depth_of_coverage.run previous_job_id
    end

    def haplotype_caller dirs, order, previous_job_id, input
      opts = { input: input, dirs: dirs, order: order }
      haplotype_caller = CagnutGatk::HaplotypeCaller.new opts
      haplotype_caller.run previous_job_id
    end

    def unified_genotyper dirs, order, previous_job_id, input
      opts = { input: input, dirs: dirs, order: order }
      unifiedgenotyper = CagnutGatk::UnifiedGenotyper.new opts
      unifiedgenotyper.run previous_job_id
    end

    def variant_filtration dirs, order, previous_job_id, input
      opts = { input: input, dirs: dirs, order: order }
      variant_filtration = CagnutGatk::VariantFiltration.new opts
      variant_filtration.run previous_job_id
    end

    def variant_eval dirs, order, previous_job_id, input
      opts = { input: input, dirs: dirs, order: order }
      variant_eval = CagnutGatk::VariantEval.new opts
      variant_eval.run previous_job_id
    end
  end
end
