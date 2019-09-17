lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "pipeline_stats/version"

Gem::Specification.new do |spec|
  spec.name          = "pipeline_stats"
  spec.version       = PipelineStats::VERSION
  spec.authors       = ["Josh Cooper"]
  spec.email         = ["josh@puppet.com"]

  spec.summary       = %q{Collect traces for Jenkins pipelines.}
  spec.description   = %q{Collect traces for Jenkins pipelines.}
  spec.homepage      = "https://github.com/joshcooper/pipeline_stats"
  spec.license       = "Apache-2.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/joshcooper/pipeline_stats"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "jenkins_api_client"
  spec.add_dependency "jaeger-client"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
