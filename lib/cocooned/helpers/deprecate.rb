# frozen_string_literal: true

require 'rubygems/deprecate'

module Cocooned
  module Helpers
    # Extend the standard Gem::Deprecation module to add a deprecation
    # method that specify the gem release where methods will disappear
    # instead of a date.
    module Deprecate
      extend Gem::Deprecate

      module_function

      def deprecate_release_message(target_and_name, replacement, release = '3.0', location = nil)
        [
          "NOTE: #{target_and_name} is deprecated",
          replacement == :none ? ' with no replacement' : "; use #{replacement} instead",
          format('. It will dissapear in %<release>s.', release: release),
          location.nil? ? '' : "\n#{target_and_name} called from #{location}"
        ].join.strip
      end

      def deprecate_release(name, replacement, release = '3.0')
        class_eval do
          old = "_deprecated_#{name}"
          alias_method old, name
          define_method name do |*args, &block|
            klass = is_a? Module
            target = klass ? "#{self}." : "#{self.class}#"

            unless Gem::Deprecate.skip
              warn(deprecate_release_message(
                     "#{target}#{name}",
                     replacement,
                     release,
                     Gem.location_of_caller.join(':')
                   ))
            end

            send old, *args, &block
          end
        end
      end
    end
  end
end
