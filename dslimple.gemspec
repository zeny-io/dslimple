# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dslimple/version'

Gem::Specification.new do |spec|
  spec.name          = 'dslimple'
  spec.version       = Dslimple::VERSION
  spec.authors       = ['Sho Kusano']
  spec.email         = ['sho-kusano@zeny.io']

  spec.summary       = 'DSLimple is a tool to manage DNSimple.'
  spec.description   = 'DSLimple is a tool to manage DNSimple. It defines the state of DNSimple using DSL, and updates DNSimple according to DSL.'
  spec.homepage      = 'https://github.com/zeny-io/dslimple'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'

  spec.add_dependency 'dnsimple', '~> 4.0'
  spec.add_dependency 'thor', '~> 0.19'
end
