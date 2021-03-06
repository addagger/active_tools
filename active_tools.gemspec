# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_tools/version'

Gem::Specification.new do |gem|
  gem.name          = "active_tools"
  gem.version       = ActiveTools::VERSION
  gem.authors       = ["Valery Kvon"]
  gem.email         = ["addagger@gmail.com"]
  gem.homepage      = %q{http://vkvon.ru/projects/active_tools}
  gem.description   = %q{Missing tools for Rails developers}
  gem.summary       = %q{ActionDispatch, ActionController, ActiveModel, ActiveRecord, ActiveSupport, ActionView and core extensions}

  gem.rubyforge_project = "active_tools"

  gem.add_runtime_dependency "rails", ">= 5"
  gem.add_development_dependency "rspec", ">= 0"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
