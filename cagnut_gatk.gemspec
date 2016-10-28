# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cagnut_gatk/version'

Gem::Specification.new do |spec|
  spec.name          = "cagnut_gatk"
  spec.version       = CagnutGatk::VERSION
  spec.authors       = ['Shi-Gang Wang', 'Tse-Ching Ho']
  spec.email         = ['seanwang@goldenio.com', 'tsechingho@goldenio.com']

  spec.summary       = %q{Cagnut Gatk tools}
  spec.description   = %q{Cagnut Gatk tools}
  spec.homepage      = "https://github.com/cagnut/cagnut_gatk"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "127.0.0.1"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'cagnut'

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
