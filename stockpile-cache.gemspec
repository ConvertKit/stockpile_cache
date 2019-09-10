# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'stockpile/constants'

Gem::Specification.new do |spec|
  spec.name          = 'stockpile_cache'
  spec.version       = Stockpile::VERSION
  spec.authors       = ['ConvertKit, LLC']
  spec.email         = ['engineering@convertkit.com']

  spec.summary       = 'Simple Redis based cache'
  spec.description   = 'Cache with cache-stampede protection'
  spec.homepage      = 'https://convertkit.com'
  spec.license       = 'Apache License Version 2.0'

  spec.files = `git ls-files | grep -Ev '^(spec)'`.split("\n")

  spec.executables = ['console']
  spec.require_paths = ['lib']

  spec.add_dependency 'connection_pool'
  spec.add_dependency 'oj'
  spec.add_dependency 'rake'
  spec.add_dependency 'redis'
end
