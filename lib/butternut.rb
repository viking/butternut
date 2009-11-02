require 'rubygems'
require 'cucumber'
require 'celerity'

module Butternut
  def self.setup_hooks(obj)
    obj.instance_exec do
      Before do |object|
        begin
          if object.is_a?(Cucumber::Ast::Scenario)
            object.page_sources = []
          end
        rescue Exception => e
          p e
          pp caller
        end
      end

      AfterStep do |object|
        begin
          if object.is_a?(Cucumber::Ast::Scenario)
            object.page_sources << (page_changed? ? current_page_source : nil)
            @page_changed = false
            p object.page_sources.collect(&:class)
          end
        rescue Exception => e
          p e
          pp caller
        end
      end
    end
  end
end

require File.dirname(__FILE__) + "/butternut/scenario_extensions"
require File.dirname(__FILE__) + "/butternut/helpers"
require File.dirname(__FILE__) + "/butternut/formatter"

