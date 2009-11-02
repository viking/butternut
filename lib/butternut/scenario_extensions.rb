module Butternut
  module ScenarioExtensions
    attr_accessor :page_sources
  end
end

Cucumber::Ast::Scenario.send(:include, Butternut::ScenarioExtensions)
