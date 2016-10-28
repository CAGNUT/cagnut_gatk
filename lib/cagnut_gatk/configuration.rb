require 'singleton'

module CagnutGatk
  class Configuration

    include Singleton
    attr_accessor :analyze_covariates_params, :base_recalibrator_params,
                  :count_reads_params, :depth_of_coverage_params,
                  :haplotype_caller_params, :indel_realigner_params,
                  :print_reads_params, :realigner_target_creator_params,
                  :unified_genotyper_params, :variant_eval_params,
                  :variant_filtration_params

    class << self
      def load config, params
        instance.load config, params
      end
    end

    def load config, params
      @config = config
      @params = params
      attributes.each do |name, value|
        send "#{name}=", value if respond_to? "#{name}="
      end
    end

    def attributes
      {
        analyze_covariates_params: add_java_params(@params['analyze_covariates']),
        base_recalibrator_params: add_java_params(@params['base_recalibrator']),
        count_reads_params: add_java_params(@params['count_reads']),
        depth_of_coverage_params: add_java_params(@params['depth_of_coverage'], true),
        haplotype_caller_params: add_java_params(@params['haplotype_caller']),
        indel_realigner_params: add_java_params(@params['indel_realigner']),
        print_reads_params: add_java_params(@params['print_reads']),
        realigner_target_creator_params: add_java_params(@params['realigner_target_creator']),
        unified_genotyper_params: add_java_params(@params['unified_genotyper']),
        variant_eval_params: add_java_params(@params['variant_eval']),
        variant_filtration_params: add_java_params(@params['variant_filtration'])
      }
    end

    def add_java_params method_params, verbose=false
      return if method_params.blank?
      array = method_params['java'].dup
      array << "-verbose:sizes" if verbose
      array << "-jar #{@config['tools']['gatk']}"
      {
        'java' => array,
        'params' => method_params['params']
      }
    end

  end
end
