require 'rubygems'
gem 'rspec'
require 'spec'
require 'spec/autorun'
require 'fileutils'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'butternut'

require 'cucumber/rb_support/rb_language'
require 'nokogiri'

module SpecHelperDsl
  attr_reader :feature_content, :step_defs

  def define_feature(string)
    @feature_content = string
  end

  def define_steps(&block)
    @step_defs = block
  end
end

module SpecHelper
  def run_defined_feature
    setup_world
    define_steps
    features = load_features(self.class.feature_content || raise("No feature content defined!"))
    run(features)
  end

  def step_mother
    @step_mother ||= Cucumber::StepMother.new
  end

  def load_features(content)
    feature_file = Cucumber::FeatureFile.new('spec.feature', content)
    features = Cucumber::Ast::Features.new
    features.add_feature feature_file.parse(step_mother, {})
    features
  end

  def run(features)
    # options = { :verbose => true }
    options = {}
    tree_walker = Cucumber::Ast::TreeWalker.new(step_mother, @formatter ? [@formatter] : [], options, STDOUT)
    tree_walker.visit_features(features)
  end

  def dsl
    unless @dsl
      rb = step_mother.load_programming_language('rb')
      @dsl = Object.new
      @dsl.extend Cucumber::RbSupport::RbDsl
    end
    @dsl
  end

  def define_steps
    return unless step_defs = self.class.step_defs
    dsl.instance_exec &step_defs
  end

  def setup_world
    dsl.instance_exec do
      Butternut.setup_hooks(self)
      World(Butternut::Helpers)
    end
  end
end

FIXTURE_DIR = File.expand_path(File.join(File.dirname(__FILE__), "fixtures"))

Spec::Matchers.define :be_an_existing_file do
  match { |filename| File.exist?(filename) }
end

Spec::Matchers.define :be_an_existing_directory do
  match { |filename| File.directory?(filename) }
end

Spec::Matchers.define :match_content_of do |expected|
  match do |actual|
    raise "expected file doesn't exist" unless File.exist?(expected)
    raise "actual file doesn't exist"   unless File.exist?(actual)
    open(expected).read == open(actual).read
  end
end


Spec::Runner.configure do |config|
  config.before(:each) do
    Cucumber::Parser::NaturalLanguage.instance_variable_set(:@languages, nil)
  end
end
