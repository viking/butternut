require 'rubygems'
require 'cucumber'
require 'celerity'

module Butternut
  def self.setup_hooks(obj)
    obj.instance_exec do
      AfterStep do |object|
        if object.is_a?(Cucumber::Ast::Scenario)
          if page_changed?
            object.last_page_source = current_page_source
            object.last_page_url    = current_url
          else
            object.last_page_source = nil
            object.last_page_url    = nil
          end
          @page_changed = false
        end
      end
    end
  end
end

require File.dirname(__FILE__) + "/butternut/scenario_extensions"
require File.dirname(__FILE__) + "/butternut/helpers"
require File.dirname(__FILE__) + "/butternut/formatter"

