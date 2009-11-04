module Butternut
  module ScenarioExtensions
    attr_accessor :last_page_source, :last_page_url
  end
end

Cucumber::Ast::Scenario.send(:include, Butternut::ScenarioExtensions)
