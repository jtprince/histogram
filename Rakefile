require 'rubygems'
require 'rake'
require 'jeweler'
require 'rake/testtask'
require 'rcov/rcovtask'

NAME = "histogram"

gemspec = Gem::Specification.new do |s|
  s.name = NAME
  s.authors = ["John T. Prince"]
  s.email = "jtprince@gmail.com"
  s.homepage = "https://github.com/jtprince/histogram"
  s.summary = "histograms data in different ways"
  s.description = "gives Arrays or NArrays the ability to 'histogram'.  Also see the 'aggregate' gem."
  s.add_development_dependency("narray")
  s.add_development_dependency("spec-more")
end

Jeweler::Tasks.new(gemspec)

Rake::TestTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.verbose = true
end

Rcov::RcovTask.new do |spec|
  spec.libs << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.verbose = true
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.read('VERSION')
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = NAME + ' ' + version
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :default => :spec

task :build => :gemspec

