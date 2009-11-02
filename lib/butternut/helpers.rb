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
      browser.page ? browser.page.as_xml : nil
    end

    # Fill in a text field with a value
    def fill_in(label_or_name, options = {})
      elt = find_element_by_label_or_name(:text_field, label_or_name)
      if elt.exist?
        elt.value = options[:with]
        @page_changed = true
      end
    end

    def select(option_text, options = {})
      elt = find_element_by_label_or_name(:select_list, options[:from])
      if elt.exist?
        elt.select(option_text)
        @page_changed = true
      end
    end

    def click_button(button_value)
      browser.button(button_value).click
      @page_changed = true
    end

    def page_changed?
      @page_changed
    end

    def find_element_by_label_or_name(type, label_or_name)
      elt = browser.send(type, :label, label_or_name)
      elt.exist? ? elt : browser.send(type, :name, label_or_name)
    end
  end
end
