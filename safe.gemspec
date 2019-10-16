# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

version = File.read(File.expand_path("VERSION", __dir__)).strip

Gem::Specification.new do |spec|
  spec.name          = "safe"
  spec.version       = version
  spec.authors       = ["Denis Tierno"]
  spec.email         = ["denis.tierno@caiena.net"]
  spec.summary       = "Monitored and organized job execution based on Gush"
  spec.description   = "Monitored and organized job execution based on Gush"
  spec.homepage      = "https://github.com/caiena/safe"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = "safe"
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activejob", ">= 4.2.7"
  spec.add_dependency "activerecord", ">= 4.2.7"
  spec.add_dependency "connection_pool", "~> 2.2.1"
  spec.add_dependency "multi_json", "~> 1.11"
  spec.add_dependency "redis", ">= 3.2", "< 5"
  spec.add_dependency "redis-mutex", "~> 4.0.1"
  spec.add_dependency "hiredis", "~> 0.6"
  spec.add_dependency "ruby-graphviz", "~> 1.2"
  spec.add_dependency "terminal-table", "~> 1.4"
  spec.add_dependency "colorize", "~> 0.7"
  spec.add_dependency "thor", "~> 0.19"
  spec.add_dependency "launchy", "~> 2.4"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.4"
  spec.add_development_dependency "rspec", '~> 3.0'
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency 'combustion', '~> 1.1'
  spec.add_development_dependency "pry", '~> 0.10'
  spec.add_development_dependency 'fakeredis', '~> 0.5'
end
