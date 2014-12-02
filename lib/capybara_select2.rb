require "capybara_select2/version"

module Capybara
  module Select2
    class Element
      attr_accessor :page, :search_enabled, :multiselect, :container

      def initialize(page_context, options = {})
        self.page = page_context
        self.search_enabled = !!options[:search]
        self.multiselect = !!options[:multiple]
        find_container(options.slice(:from, :xpath))
      end

      def drop_container_class
        if search_enabled then '.select2-results' else '.select2-drop' end
      end

      def select_match!
        page.find(:css, drop_container_class).find(:css, ".select2-match").click
      end

      def initiate!(value)
        focus!
        search!(value) if search_enabled
      end

      private
      def find_container(options)
        if options[:xpath].present?
          self.container = page.first(:xpath, options[:xpath])
        else
          label = page.first("label", text: options[:from]) || page.first(options[:from])
          self.container = label.find(:xpath, '..').find(".select2-container")
        end
      end

      def focus!
        css_class = if multiselect then '.select2-choices' else '.select2-choice' end
        container.find(css_class).click
      end

      def search!(value)
        page.find(:xpath, "//body").find("input.select2-input").set(value)
        page.execute_script(%|$("input.select2-input:visible").keyup();|)
      end
    end
  end
end

# This module gets included in the Cucumber or RSpec World
module Capybara
  module Select2
    def select2(value, options = {})
      raise "Must pass a hash containing 'from' or 'xpath'" unless options.is_a?(Hash) and [:from, :xpath].any? { |k| options.has_key? k }
      element = Capybara::Select2::Element.new(self, options)
      element.initiate!(value)
      element.select_match!
    end
  end
end
