require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |t|
  require 'simplecov'
  SimpleCov.command_name 'Unit Tests'

  require 'coveralls'
  Coveralls.wear!

  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end
