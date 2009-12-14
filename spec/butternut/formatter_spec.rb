require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Butternut
  describe Formatter do
    extend SpecHelperDsl
    include SpecHelper

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

    it "should be a subclass of the html formatter" do
      Butternut::Formatter.superclass.should == Cucumber::Formatter::Html
    end

    describe "running without the --out option" do
      define_steps do
        Given(/foo/) do
          visit("file://" + File.expand_path(File.dirname(__FILE__) + "/../fixtures/foo.html"))
        end
      end

      define_feature(<<-FEATURE)
        Scenario: Monkey goes to the zoo
          Given foo
      FEATURE

      it "should raise an error" do
        lambda {
          setup_formatter
          run_defined_feature
        }.should raise_error
      end
    end

    describe "running with the --out option" do
      before(:each) do
        dir = File.join(File.dirname(__FILE__), "..", "..", "tmp")
        @tmp_dir = File.join(dir, "#{Time.now.to_i}-#{rand(1000)}")
        FileUtils.mkdir(@tmp_dir)

        #@tmp_dir = File.join(dir, "features", Date.today.to_s)
        #file = most_recent_html_file(@tmp_dir)
        #@page_doc = Nokogiri.HTML(open(file).read)
      end

      describe "with a filename specified" do
        define_steps do
          Given(/foo/) do
            visit("file://" + File.join(FIXTURE_DIR, "foo.html"))
          end
        end

        define_feature(<<-FEATURE)
          Scenario: Monkey goes to the zoo
            Given foo
            Then bar
        FEATURE

        before(:each) do
          setup_formatter({
            :formats => [
              ['Butternut::Formatter', File.join(@tmp_dir, "output.html")]
            ]
          })
          run_defined_feature
          @doc = Nokogiri.HTML(@out.string)

          file = most_recent_html_file(File.join(@tmp_dir, "output"))
          @page_doc = Nokogiri.HTML(open(file).read)
        end

        it "creates assets directory" do
          File.join(@tmp_dir, "output").should be_an_existing_directory
        end

        it "links to the page source" do
          step = @doc.at('.feature .scenario .step.passed')
          link = step.at("a")
          link.should_not be_nil
          file = link['href']
          file.should match(%r{^output/butternut.+\.html})
        end

        it "saves images and stylesheets and rewrites urls in page source" do
          @page_doc.at('img:nth(1)')['src'].should == "picard.jpg"
          File.join(@tmp_dir, "output", "picard.jpg").should be_an_existing_file

          @page_doc.at('link:nth(1)[rel="stylesheet"]')['href'].should == "foo.css"
          File.join(@tmp_dir, "output", "foo.css").should be_an_existing_file

          @page_doc.at('link:nth(2)[rel="stylesheet"]')['href'].should == "bar.css"
          File.join(@tmp_dir, "output", "bar.css").should be_an_existing_file
        end

        it "saves assets and rewrites urls referred to by stylesheets" do
          foo = open(File.join(@tmp_dir, "output", "foo.css")).read
          foo.should include("url(facepalm.jpg)")
          File.join(@tmp_dir, "output", "facepalm.jpg").should be_an_existing_file
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

        it "handles badly formed URI's" do
        end
      end
    end
  end
end
