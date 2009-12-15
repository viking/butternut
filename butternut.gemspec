# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{butternut}
  s.version = "0.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jeremy Stephens"]
  s.date = %q{2009-12-15}
  s.description = %q{Based on Cucumber's HTML formatter, Butternut uses Celerity to capture page sources after each step.}
  s.email = %q{viking415@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "butternut.gemspec",
     "lib/butternut.rb",
     "lib/butternut/cucumber.css",
     "lib/butternut/cucumber.sass",
     "lib/butternut/formatter.rb",
     "lib/butternut/helpers.rb",
     "lib/butternut/scenario_extensions.rb",
     "spec/butternut/formatter_spec.rb",
     "spec/butternut/helpers_spec.rb",
     "spec/butternut_spec.rb",
     "spec/fixtures/blargh.html",
     "spec/fixtures/css/bar.css",
     "spec/fixtures/facepalm.jpg",
     "spec/fixtures/foo.css",
     "spec/fixtures/foo.html",
     "spec/fixtures/foo.js",
     "spec/fixtures/picard.jpg",
     "spec/spec.opts",
     "spec/spec_helper.rb",
     "tmp/.gitignore"
  ]
  s.homepage = %q{http://github.com/viking/butternut}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{A Cucumber formatter that uses Celerity to capture HTML sources (JRuby)}
  s.test_files = [
    "spec/butternut_spec.rb",
     "spec/spec_helper.rb",
     "spec/butternut/formatter_spec.rb",
     "spec/butternut/helpers_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<cucumber>, [">= 0.4.0"])
      s.add_runtime_dependency(%q<celerity>, [">= 0"])
      s.add_runtime_dependency(%q<nokogiri>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
    else
      s.add_dependency(%q<cucumber>, [">= 0.4.0"])
      s.add_dependency(%q<celerity>, [">= 0"])
      s.add_dependency(%q<nokogiri>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 1.2.9"])
    end
  else
    s.add_dependency(%q<cucumber>, [">= 0.4.0"])
    s.add_dependency(%q<celerity>, [">= 0"])
    s.add_dependency(%q<nokogiri>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 1.2.9"])
  end
end

