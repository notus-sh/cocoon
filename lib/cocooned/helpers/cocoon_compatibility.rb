# frozen_string_literal: true

require 'cocooned/helpers/deprecate'

module Cocooned
  module Helpers
    # Provide aliases to old Cocoon method for backward compatibility.
    # Cocoon methods are deprecated and will be removed in next major release.
    #
    # TODO: Remove in 3.0
    module CocoonCompatibility
      extend Cocooned::Helpers::Deprecate

      # @deprecated: Please use {#cocooned_add_item_link} instead
      def link_to_add_association(*args, &block)
        cocooned_add_item_link(*args, &block)
      end
      deprecate_release :link_to_add_association, :cocooned_add_item_link

      # @deprecated: Please use {#cocooned_remove_item_link} instead
      def link_to_remove_association(*args, &block)
        cocooned_remove_item_link(*args, &block)
      end
      deprecate_release :link_to_remove_association, :cocooned_remove_item_link
    end
  end
end
