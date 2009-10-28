require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Butternut do
  extend SpecHelperDsl
  include SpecHelper

  describe "saving html snapshots after each step" do
    describe "given the page changes" do
      define_steps do
        Given("blargh") { }
      end

      define_feature <<-FEATURE
        Scenario: omg
          Given blargh
      FEATURE

      it { run_defined_feature }
    end
  end
end
