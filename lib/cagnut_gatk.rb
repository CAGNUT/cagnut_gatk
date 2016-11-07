require "cagnut_gatk/version"

module CagnutGatk
  class << self
    def config
      @config ||= begin
        CagnutGatk::Configuration.load(Cagnut::Configuration.config, Cagnut::Configuration.params['gatk'])
        CagnutGatk::Configuration.instance
      end
    end
  end
end

require 'cagnut_gatk/configuration'
require 'cagnut_gatk/check_tools'
require 'cagnut_gatk/base'
require 'cagnut_gatk/util'
