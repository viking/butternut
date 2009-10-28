require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Butternut
  describe Helpers do
    include Helpers

    def define_stub_chain
      # This is what I hate about RSpec.
      @stub_request_url = stub("fake request url", :toString => "http://example.com")
      @stub_response = stub("fake web response", :getRequestUrl => @stub_request_url)
      @stub_page = stub("fake html page", {
        :as_xml => "<cheese>pepperjack</cheese>",
        :getWebResponse => @stub_response
      })
      @stub_element = stub("fake element", :value= => nil, :select => nil, :click => nil)

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
        @stub_request_url.should_receive(:toString).and_return("http://google.com")
        current_url.should == "http://google.com"
      end
    end

    describe "#current_page_source" do
      before(:each) { define_stub_chain }
      it do
        @stub_page.should_receive(:as_xml).and_return("pants")
        current_page_source.should == "pants"
      end
    end

    describe "#fill_in" do
      before(:each) { define_stub_chain }
      it do
        @stub_browser.should_receive(:text_field).with(:label, "pants").and_return(@stub_element)
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
      it do
        @stub_browser.should_receive(:select_list).with(:label, "pants").and_return(@stub_element)
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
