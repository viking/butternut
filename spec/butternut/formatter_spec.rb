require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Butternut
  describe Formatter do
    extend SpecHelperDsl
    include SpecHelper

    Spec::Matchers.define :have_css_node do |css, regexp|
      match do |doc|
        nodes = doc.css(css)
        nodes.detect{ |node| node.text =~ regexp }
      end
    end

    def setup_formatter(options = {})
      @out = StringIO.new
      @formatter = Butternut::Formatter.new(step_mother, @out, options)
    end

    def most_recent_html_file(dir)
      path = Pathname.new(dir)
      files = path.entries.collect { |file|
        path+file
      }.sort { |file1,file2|
        file2.mtime <=> file1.mtime
      }
      files.detect { |f| f.to_s =~ /\.html$/ }
    end

    describe "visiting blank feature name" do
      before(:each) do
        setup_formatter
      end

      it "should not raise an error when visiting a blank feature name" do
        lambda { @formatter.feature_name("") }.should_not raise_error
      end
    end

    describe "given a single feature" do
      before(:each) do
        setup_formatter
        run_defined_feature
        @doc = Nokogiri.HTML(@out.string)
      end

      describe "with a comment" do
        define_feature <<-FEATURE
          # Healthy
        FEATURE

        it { @out.string.should =~ /^\<!DOCTYPE/ }
        it { @out.string.should =~ /\<\/html\>$/ }
        it { @doc.should have_css_node('.feature .comment', /Healthy/) }
      end

      describe "with a tag" do
        define_feature <<-FEATURE
          @foo
        FEATURE

        it { @doc.should have_css_node('.feature .tag', /foo/) }
      end

      describe "with a narrative" do
        define_feature <<-FEATURE
          Feature: Bananas
            In order to find my inner monkey
            As a human
            I must eat bananas
        FEATURE

        it { @doc.should have_css_node('.feature h2', /Bananas/) }
        it { @doc.should have_css_node('.feature .narrative', /must eat bananas/) }
      end

      describe "with a background" do
        define_feature <<-FEATURE
          Feature: Bananas

          Background:
            Given there are bananas
        FEATURE

        it { @doc.should have_css_node('.feature .background', /there are bananas/) }
      end

      describe "with a scenario" do
        define_feature <<-FEATURE
          Scenario: Monkey eats banana
            Given there are bananas
        FEATURE

        it { @doc.should have_css_node('.feature h3', /Monkey eats banana/) }
        it { @doc.should have_css_node('.feature .scenario .step', /there are bananas/) }
      end

      describe "with a scenario outline" do
        define_feature <<-FEATURE
          Scenario Outline: Monkey eats a balanced diet
            Given there are <Things>

            Examples: Fruit
             | Things  |
             | apples  |
             | bananas |
            Examples: Vegetables
             | Things   |
             | broccoli |
             | carrots  |
        FEATURE

        it { @doc.should have_css_node('.feature .scenario.outline h4', /Fruit/) }
        it { @doc.should have_css_node('.feature .scenario.outline h4', /Vegetables/) }
        it { @doc.css('.feature .scenario.outline h4').length.should == 2}
        it { @doc.should have_css_node('.feature .scenario.outline table', //) }
        it { @doc.should have_css_node('.feature .scenario.outline table td', /carrots/) }
      end

      describe "with a step with a py string" do
        define_feature <<-FEATURE
          Scenario: Monkey goes to town
            Given there is a monkey called:
             """
             foo
             """
        FEATURE

        it { @doc.should have_css_node('.feature .scenario .val', /foo/) }
      end

      describe "with a multiline step arg" do
        define_feature <<-FEATURE
          Scenario: Monkey goes to town
            Given there are monkeys:
             | name |
             | foo  |
             | bar  |
        FEATURE

        it { @doc.should have_css_node('.feature .scenario table td', /foo/) }
      end

      describe "with a table in the background and the scenario" do
        define_feature <<-FEATURE
          Background:
            Given table:
              | a | b |
              | c | d |
          Scenario:
            Given another table:
             | e | f |
             | g | h |
        FEATURE

        it { @doc.css('tr.step td table tr td').length.should == 8 }
      end

      describe "with a py string in the background and the scenario" do
        define_feature <<-FEATURE
          Background:
            Given stuff:
              """
              foo
              """
          Scenario:
            Given more stuff:
              """
              bar
              """
        FEATURE

        it { @doc.css('.feature .background pre.val').length.should == 1 }
        it { @doc.css('.feature .scenario pre.val').length.should == 1 }
      end

      describe "with a step that fails in the scenario" do
        define_steps do
          Given(/boo/) { raise 'eek' }
        end

        define_feature(<<-FEATURE)
          Scenario: Monkey gets a fright
            Given boo
        FEATURE

        it { @doc.should have_css_node('.feature .scenario .step.failed', /eek/) }
      end

      describe "with a step that fails in the backgound" do
        define_steps do
          Given(/boo/) { raise 'eek' }
        end

        define_feature(<<-FEATURE)
          Background:
            Given boo
          Scenario:
            Given yay
          FEATURE

        it { @doc.should have_css_node('.feature .background .step.failed', /eek/) }
        it { @doc.should_not have_css_node('.feature .scenario .step.failed', //) }
        it { @doc.should have_css_node('.feature .scenario .step.undefined', /yay/) }
      end
    end

    describe "displaying page source to stdout" do
      before(:each) do
        setup_formatter
        run_defined_feature
        @doc = Nokogiri.HTML(@out.string)
      end

      define_steps do
        Given(/foo/) do
          visit("file://" + File.expand_path(File.dirname(__FILE__) + "/../fixtures/foo.html"))
        end
      end

      define_feature(<<-FEATURE)
        Scenario: Monkey goes to the zoo
          Given foo
      FEATURE

      it do
        step = @doc.at('.feature .scenario .step.passed')
        link = step.at('a[href^="file:///tmp/"]')
        link.should_not be_nil
      end
    end

    describe "displaying page source to file" do
      before(:each) do
        @tmpdir = File.join(File.dirname(__FILE__), "..", "..", "tmp")
        setup_formatter({:formats => [
          ['Butternut::Formatter', File.join(@tmpdir, "main", "huge.html")]
        ]})
        run_defined_feature
        @doc = Nokogiri.HTML(@out.string)
      end

      define_steps do
        Given(/foo/) do
          visit("file://" + File.expand_path(File.dirname(__FILE__) + "/../fixtures/foo.html"))
        end
      end

      define_feature(<<-FEATURE)
        Scenario: Monkey goes to the zoo
          Given foo
      FEATURE

      it "links to the page source and rewrites urls" do
        step = @doc.at('.feature .scenario .step.passed')
        link = step.at("a")
        link.should_not be_nil
        file = link['href']
        file.should match(%r{^\.\./features/#{Date.today.to_s}/butternut.+\.html})
      end

      it "saves images and stylesheets and rewrites urls in page source" do
        dir = File.join(@tmpdir, "features", Date.today.to_s)
        file = most_recent_html_file(dir)
        doc = Nokogiri.HTML(open(file).read)
        doc.at('img')['src'].should == "picard.jpg"
        doc.at('link[rel="stylesheet"]')['href'].should == "foo.css"
      end
    end
  end
end
