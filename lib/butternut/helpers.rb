module Butternut
  module Helpers
    def browser
      @browser ||= Celerity::Browser.new
    end

    def visit(url)
      browser.goto(url)
      @page_changed = true
    end

    def current_url
      browser.page.getWebResponse.getRequestUrl.toString
    end

    def current_page_source
      browser.page.as_xml
    end

    def fill_in(label_for_text_field, options = {})
      browser.text_field(:label, label_for_text_field).value = options[:with]
      @page_changed = true
    end

    def select(option_text, options = {})
      browser.select_list(:label, options[:from]).select(option_text)
      @page_changed = true
    end

    def click_button(button_value)
      browser.button(button_value).click
      @page_changed = true
    end

    def page_changed?
      @page_changed
    end
  end
end
