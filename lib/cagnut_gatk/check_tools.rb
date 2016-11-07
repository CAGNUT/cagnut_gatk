module CagnutGatk
  module CheckTools
    def check_tool tools_path, refs=nil
      super if defined?(super)
      check_gatk tools_path['gatk'] if @java
    end

    def check_gatk path
      check_tool_ver 'GATK' do
        `#{@java} -jar #{path} --version` if path
      end
    end
  end
end

Cagnut::Configuration::Checks::Tools.prepend CagnutGatk::CheckTools
