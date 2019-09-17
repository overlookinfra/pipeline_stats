require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :default => :test

desc "Publish traces"
task :publish do
  traces = FileList['traces/puppet-agent-*.yaml']
  traces.each do |trace|
    puts "Publishing #{trace}"
    %x(bundle exec tracer #{trace})
  end
end
