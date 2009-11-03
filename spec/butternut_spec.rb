require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Butternut do
  describe "running a scenario" do
    extend SpecHelperDsl
    include SpecHelper

    describe "saving last page source" do
      define_steps do
        Given('waffles') do
          visit("file://" + File.expand_path(File.dirname(__FILE__) + "/fixtures/foo.html"))
        end
        AfterStep do |scenario|
          begin
            scenario.page_sources[0].should match(/Foo/)
          rescue Exception => e
            p e
          end
        end
      end

      define_feature <<-FEATURE
        Scenario: Roffle waffles
          Given waffles
      FEATURE

      it { run_defined_feature }
    end

    describe "resetting page_changed" do
      define_steps do
        Given('waffles') do
          visit("file://" + File.expand_path(File.dirname(__FILE__) + "/fixtures/foo.txt"))
        end
        AfterStep do |scenario|
          begin
            page_changed?.should be_false
          rescue Exception => e
            p e
          end
        end
      end

      define_feature <<-FEATURE
        Scenario: Roffle waffles
          Given waffles
      FEATURE

      it { run_defined_feature }
    end
  end
end
