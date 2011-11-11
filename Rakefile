# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "netloc"
  gem.homepage = "http://github.com/bkayser/netloc"
  gem.license = "MIT"
  gem.summary = %Q{Report on summary changes in a commit}
  gem.description = %Q{TODO: longer description of your gem}
  gem.email = "bkayser@newrelic.com"
  gem.authors = ["Bill Kayser"]
  gem.executables = %W(netloc)
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

