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

    Spec::Matchers.define :be_an_existing_file do
      match do |filename|
        File.exist?(filename)
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

        it { @doc.css('td').length.should == 8 }
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
        dir = File.join(File.dirname(__FILE__), "..", "..", "tmp")
        setup_formatter({:formats => [
          ['Butternut::Formatter', File.join(dir, "main", "huge.html")]
        ]})
        run_defined_feature
        @doc = Nokogiri.HTML(@out.string)

        @tmp_dir = File.join(dir, "features", Date.today.to_s)
        file = most_recent_html_file(@tmp_dir)
        @page_doc = Nokogiri.HTML(open(file).read)
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

      it "links to the page source" do
        step = @doc.at('.feature .scenario .step.passed')
        link = step.at("a")
        link.should_not be_nil
        file = link['href']
        file.should match(%r{^/features/#{Date.today.to_s}/butternut.+\.html})
      end

      it "saves images and stylesheets and rewrites urls in page source" do
        @page_doc.at('img:nth(1)')['src'].should == "picard.jpg"
        File.join(@tmp_dir, "picard.jpg").should be_an_existing_file

        @page_doc.at('link:nth(1)[rel="stylesheet"]')['href'].should == "foo.css"
        File.join(@tmp_dir, "foo.css").should be_an_existing_file

        @page_doc.at('link:nth(2)[rel="stylesheet"]')['href'].should == "bar.css"
        File.join(@tmp_dir, "bar.css").should be_an_existing_file
      end

      it "saves assets and rewrites urls referred to by stylesheets" do
        foo = open(File.join(@tmp_dir, "foo.css")).read
        foo.should include("url(facepalm.jpg)")
        File.join(@tmp_dir, "facepalm.jpg").should be_an_existing_file
      end

      it "turns off links" do
        @page_doc.css('a').each do |link|
          link['href'].should == "#"
        end
      end

      it "turns off scripts" do
        @page_doc.css('script').length.should == 0
      end

      it "disables form elements" do
        @page_doc.css('input, select, textarea').each do |elt|
          elt['disabled'].should == "disabled"
        end
      end

      it "handles Errno::ENOENT" do
        @page_doc.at('img:nth(2)')['src'].should == "/roflpwnage/missing_file_omg.gif"
      end

      it "handles OpenURI::HTTPError" do
        @page_doc.at('img:nth(3)')['src'].should == "http://google.com/missing_file_omg.gif"
      end

      it "handles Net::FTPPermError" do
        @page_doc.at('img:nth(4)')['src'].should == "ftp://mirror.anl.gov/missing_file_omg.gif"
      end
    end
  end
end
