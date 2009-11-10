require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "butternut"
    gem.summary = %Q{A Cucumber formatter that uses Celerity to capture HTML sources (JRuby)}
    gem.description = %Q{Based on Cucumber's HTML formatter, Butternut uses Celerity to capture page sources after each step.}
    gem.email = "viking415@gmail.com"
    gem.homepage = "http://github.com/viking/butternut"
    gem.authors = ["Jeremy Stephens"]
    gem.add_dependency "cucumber", ">= 0.4.0"
    gem.add_dependency "celerity"
    gem.add_dependency "nokogiri"
    gem.add_development_dependency "rspec", ">= 1.2.9"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => [:check_dependencies, "tmp:clear"]

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "butternut #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Generate the css for the html formatter from sass'
task :sass do
  sh 'sass -t expanded lib/butternut/cucumber.sass > lib/butternut/cucumber.css'
end

namespace :tmp do
  desc 'Delete temporary files'
  task :clear do
    require 'fileutils'
    FileUtils.rm_rf(Dir.glob(File.dirname(__FILE__) + "/tmp/features/*"), :verbose => true)
  end
end
