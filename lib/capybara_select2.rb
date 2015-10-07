require "capybara_select2/version"

module Capybara
  module Select2
    class Element
      attr_accessor :page, :options, :search_enabled, :multiselect, :container, :drop_container

      def initialize(page_context, options = {})
        self.page = page_context
        self.options= options
        self.search_enabled = !!options[:search]
        self.multiselect = !!options[:multiple]
        find_container(options.slice(:from, :xpath))
      end

      def drop_container_class(value)
        if options.has_key? :search
          page.find(:xpath, "//body").find(".select2-search input.select2-search__field").set(value)
          page.execute_script(%|$("input.select2-search__field:visible").keyup();|)
          ".select2-results"
        elsif page.find(:xpath, "//body").has_selector?(".select2-dropdown")
          # select2 version 4.0
          ".select2-dropdown"
        else
          ".select2-drop"
        end
      end

      def select_match!(value)
        [value].flatten.each do |value|
          if page.find(:xpath, "//body").has_selector?("#{drop_container_class(value)} li.select2-results__option")
            # select2 version 4.0
            page.find(:xpath, "//body").find("#{drop_container_class(value)} li.select2-results__option", text: value).click
          else
            page.find(:xpath, "//body").find("#{drop_container_class(value)} li.select2-result-selectable", text: value).click
          end
        end
      end

      def initiate!
        focus!
      end

      private
      def find_container(options)
        if options.has_key? :xpath
          self.container = page.find(:xpath, options[:xpath])
        elsif options.has_key? :css
          self.container = page.find(:css, options[:css])
        else
          select_name = options[:from]
          self.container = page.find("label", text: select_name).find(:xpath, '..').find(".select2-container")
        end
      end

      def focus!
        if self.container.has_selector?(".select2-selection")
          # select2 version 4.0
          self.container.find(".select2-selection").click
        elsif select2_container.has_selector?(".select2-choice")
          self.container.find(".select2-choice").click
        else
          self.container.find(".select2-choices").click
        end
      end
    end
  end
end

# This module gets included in the Cucumber, RSpec, or MiniTest World
module Capybara
  module Select2
    def select2(value, options = {})
      raise "Must pass a hash containing 'from' or 'xpath' or 'css'" unless options.is_a?(Hash) and [:from, :xpath, :css].any? { |k| options.has_key? k }

      element = Capybara::Select2::Element.new(self, options)
      element.initiate!
      element.select_match!(value)
    end
  end
end
