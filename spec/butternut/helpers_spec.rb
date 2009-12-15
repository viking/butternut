require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Butternut
  describe Helpers do
    include Helpers

    def define_stub_chain
      # This is what I hate about RSpec.
      @stub_request_url = stub("fake request url", :to_string => "http://example.com")
      @stub_response = stub("fake web response", :request_url => @stub_request_url)
      @stub_page = stub("fake html page", {
        :as_xml => "<cheese>pepperjack</cheese>",
        :web_response => @stub_response
      })
      @stub_element = stub("fake element", :value= => nil, :select => nil, :click => nil, :exist? => true)
      @stub_empty = stub("fake empty element", :exist? => false)

      @stub_browser = stub("fake celerity browser", {
        :goto => @stub_page, :page => @stub_page,
        :text_field => @stub_element, :select_list => @stub_element,
        :button => @stub_element
      })
      stub!(:browser).and_return(@stub_browser)
    end

    describe "#browser" do
      it { browser.should be_a(Celerity::Browser) }
    end

    describe "#page_changed?" do
      it { page_changed?.should_not be_true }
    end

    describe "#visit" do
      before(:each) { define_stub_chain }

      it "should go to the page" do
        @stub_browser.should_receive(:goto).with("http://google.com")
        visit("http://google.com")
      end

      it "should flag page as changed" do
        visit("http://google.com")
        page_changed?.should be_true
      end
    end

    describe "#current_url" do
      before(:each) { define_stub_chain }
      it do
        @stub_request_url.should_receive(:to_string).and_return("http://google.com")
        current_url.should == "http://google.com"
      end
    end

    describe "#current_page_source" do
      before(:each) do
        @browser = browser
        visit("file://" + File.expand_path(File.dirname(__FILE__) + "/../fixtures/blargh.html"))
      end

      it "constructs the current page's source" do
        # HtmlUnit's text node parsing it a little strange
        expected = "<html><head>\n    <title>Blargh</title>\n  </head><body>\n    <p>Foo</p>\n    <p>Bar</p>\n  \n</body></html>"
        current_page_source.should == expected
      end

      it "returns nil if page is nil" do
        @browser.stub!(:page).and_return(nil)
        current_page_source.should be_nil
      end
    end

    describe "#fill_in" do
      before(:each) { define_stub_chain }

      it "should find by label" do
        @stub_browser.should_receive(:text_field).with(:label, "pants").and_return(@stub_element)
        @stub_element.should_receive(:value=).with("khakis")
        fill_in("pants", :with => "khakis")
      end

      it "should find by name" do
        @stub_browser.should_receive(:text_field).with(:label, "pants").and_return(@stub_empty)
        @stub_browser.should_receive(:text_field).with(:name, "pants").and_return(@stub_element)
        @stub_element.should_receive(:value=).with("khakis")
        fill_in("pants", :with => "khakis")
      end

      it "should flag page as changed" do
        fill_in("pants", :with => "khakis")
        page_changed?.should be_true
      end
    end

    describe "#select" do
      before(:each) { define_stub_chain }

      it "should find by label" do
        @stub_browser.should_receive(:select_list).with(:label, "pants").and_return(@stub_element)
        @stub_element.should_receive(:select).with("khakis")
        select("khakis", :from => "pants")
      end

      it "should find by name" do
        @stub_browser.should_receive(:select_list).with(:label, "pants").and_return(@stub_empty)
        @stub_browser.should_receive(:select_list).with(:name, "pants").and_return(@stub_element)
        @stub_element.should_receive(:select).with("khakis")
        select("khakis", :from => "pants")
      end

      it "should flag page as changed" do
        select("khakis", :from => "pants")
        page_changed?.should be_true
      end
    end

    describe "#click_button" do
      before(:each) { define_stub_chain }
      it do
        @stub_browser.should_receive(:button).with("pants").and_return(@stub_element)
        @stub_element.should_receive(:click)
        click_button("pants")
      end

      it "should flag page as changed" do
        click_button("pants")
        page_changed?.should be_true
      end
    end
  end
end
