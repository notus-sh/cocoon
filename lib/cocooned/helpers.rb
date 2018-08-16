# frozen_string_literal: true

require 'cocooned/helpers/deprecate'
require 'cocooned/helpers/cocoon_compatibility'
require 'cocooned/association_builder'

module Cocooned
  # TODO: Remove in 2.0 (Only Cocoon class names).
  HELPER_CLASSES = {
    add:    ['cocooned-add', 'add_fields'],
    remove: ['cocooned-remove', 'remove_fields'],
    up:     ['cocooned-move-up'],
    down:   ['cocooned-move-down']
  }.freeze

  module Helpers
    # Create aliases to old Cocoon method name
    # TODO: Remove in 2.0
    include Cocooned::Helpers::CocoonCompatibility

    # Output an action link to add an item in a nested form.
    #
    # ==== Signatures
    #
    #   cocooned_add_item_link(label, form, association, options = {})
    #     # Explicit name
    #
    #   cocooned_add_item_link(form, association, options = {}) do
    #     # Name as a block
    #   end
    #
    #   cocooned_add_item_link(form, association, options = {})
    #     # Use default name
    #
    # `form` is your form builder. Can be a SimpleForm::Builder, Formtastic::Builder
    # or a standard Rails FormBuilder.
    #
    # `association` is the name of the nested association.
    # Ex: cocooned_add_item_link "Add an item", form, :items
    #
    # ==== Options
    #
    # `options` can be any of the following.
    #
    # Rendering options:
    #
    # - **partial**: the nested form partial.
    #   Defaults to `{association.singular_name}_fields`.
    # - **form_name**: name used to access the form builder in the nested form partial.
    #   Defaults to `:f`.
    # - **locals**: a hash of local variables, will be forwarded to the partial.
    #   No default.
    #
    # Association options:
    #
    # - **count**: how many item will be inserted on clic.
    #   Defaults to 1.
    # - **wrap_object**: a proc used to wrap item instance. Can be useful with decorators
    #   or special initialisations.
    #   No default.
    # - **force_non_association_create**: force to build instances of the nested model
    #   outside association (i.e. without calling `build_{association}` or `{association}.build`)
    #   Defaults to false.
    #
    # Link HTML options:
    #
    # You can pass any option supported by +link_to+. It will be politely forwarded.
    # See the documentation of +link_to+ for more informations.
    #
    # Compatibility options:
    #
    # These options are supported for backward compatibility with the original Cocoon.
    # **Support for these options will be removed in the next major release !**.
    #
    # - **limit**: how many items are allowed in the nested form.
    #   No default.
    #
    def cocooned_add_item_link(*args, &block)
      if block_given?
        cocooned_add_item_link(capture(&block), *args)

      elsif args.first.respond_to?(:object)
        association = args.second
        cocooned_add_item_link(cocooned_default_label(:add, association), *args)

      else
        name, form, association, html_options = *args
        html_options ||= {}

        builder_options = cocooned_extract_builder_options!(html_options)
        render_options = cocooned_extract_render_options!(html_options)

        builder = Cocooned::AssociationBuilder.new(form, association, builder_options)
        rendered = cocooned_render_association(builder, render_options)

        data = cocooned_extract_data!(html_options).merge!(
          association: builder.singular_name,
          associations: builder.plural_name,
          association_insertion_template: CGI.escapeHTML(rendered.to_str).html_safe
        )

        html_options = {
          class: [Array(html_options.delete(:class)).collect { |k| k.to_s.split(' ') },
                  Cocooned::HELPER_CLASSES[:add]].flatten.compact.uniq.join(' '),
          data: data
        }.deep_merge(html_options)

        link_to(name, '#', html_options)
      end
    end

    # Output an action link to remove an item (and an hidden field to mark
    # it as destroyed if it has already been persisted).
    #
    # ==== Signatures
    #
    #   cocooned_remove_item_link(label, form, html_options = {})
    #     # Explicit name
    #
    #   cocooned_remove_item_link(form, html_options = {}) do
    #     # Name as a block
    #   end
    #
    #   cocooned_remove_item_link(form, html_options = {})
    #     # Use default name
    #
    # See the documentation of +link_to+ for valid options.
    def cocooned_remove_item_link(name, form = nil, html_options = {}, &block)
      # rubocop:disable Style/ParallelAssignment
      html_options, form = form, nil if form.is_a?(Hash)
      form, name = name, form if form.nil?
      # rubocop:enable Style/ParallelAssignment

      return cocooned_remove_item_link(capture(&block), form, html_options) if block_given?

      association = form.object.class.to_s.tableize
      return cocooned_remove_item_link(cocooned_default_label(:remove, association), form, html_options) if name.nil?

      html_options[:class] = [html_options[:class], Cocooned::HELPER_CLASSES[:remove]].flatten.compact
      html_options[:class] << (form.object.new_record? ? 'dynamic' : 'existing')
      html_options[:class] << 'destroyed' if form.object.marked_for_destruction?

      hidden_field_tag("#{form.object_name}[_destroy]", form.object._destroy) <<
        link_to(name, '#', html_options)
    end

    # Output an action link to move an item up.
    #
    # ==== Signatures
    #
    #   cocooned_move_item_up_link(label, form, html_options = {})
    #     # Explicit name
    #
    #   cocooned_move_item_up_link(form, html_options = {}) do
    #     # Name as a block
    #   end
    #
    #   cocooned_move_item_up_link(form, html_options = {})
    #     # Use default name
    #
    # See the documentation of +link_to+ for valid options.
    def cocooned_move_item_up_link(name, form = nil, html_options = {}, &block)
      cocooned_move_item_link(:up, name, form, html_options, &block)
    end

    # Output an action link to move an item down.
    #
    # ==== Signatures
    #
    #   cocooned_move_item_down_link(label, html_options = {})
    #     # Explicit name
    #
    #   cocooned_move_item_down_link(html_options = {}) do
    #     # Name as a block
    #   end
    #
    #   cocooned_move_item_down_link(html_options = {})
    #     # Use default name
    #
    # See the documentation of +link_to+ for valid options.
    def cocooned_move_item_down_link(name, form = nil, html_options = {}, &block)
      cocooned_move_item_link(:down, name, form, html_options, &block)
    end

    private

    def cocooned_move_item_link(direction, name, form = nil, html_options = {}, &block)
      form, name = name, form if form.nil?
      return cocooned_move_item_link(direction, capture(&block), form, html_options) if block_given?
      return cocooned_move_item_link(direction, cocooned_default_label(direction), form, html_options) if name.nil?

      html_options[:class] = [html_options[:class], Cocooned::HELPER_CLASSES[direction]].flatten.compact.join(' ')
      link_to name, '#', html_options
    end

    def cocooned_default_label(action, association = nil)
      # TODO: Remove in 2.0
      if I18n.exists?(:cocoon)
        msg = Cocooned::Helpers::Deprecate.deprecate_release_message('the :cocoon i18n scope', ':cocooned')
        warn msg
      end

      keys = ["cocooned.defaults.#{action}", "cocoon.defaults.#{action}"]
      keys.unshift("cocooned.#{association}.#{action}", "cocoon.#{association}.#{action}") unless association.nil?
      keys.collect!(&:to_sym)
      keys << action.to_s.humanize

      I18n.translate(keys.take(1).first, default: keys.drop(1))
    end

    def cocooned_render_association(builder, render_options = {})
      partial = render_options.delete(:partial) || builder.singular_name + '_fields'
      locals =  render_options.delete(:locals) || {}
      form_name = render_options.delete(:form_name)

      form_options = { child_index: "new_#{builder.association}" }.merge(render_options)
      builder.form.send(cocooned_form_method(builder.form),
                        builder.association,
                        builder.build_object,
                        form_options) do |form_builder|

        partial_options = { form_name.to_sym => form_builder, :dynamic => true }.merge(locals)
        render(partial, partial_options)
      end
    end

    def cocooned_form_method(form)
      ancestors = form.class.ancestors.map(&:to_s)
      if ancestors.include?('SimpleForm::FormBuilder')
        :simple_fields_for
      elsif ancestors.include?('Formtastic::FormBuilder')
        :semantic_fields_for
      else
        :fields_for
      end
    end

    def cocooned_extract_builder_options!(html_options)
      %i[wrap_object force_non_association_create].each_with_object({}) do |option_name, opts|
        opts[option_name] = html_options.delete(option_name) if html_options.key?(option_name)
      end
    end

    def cocooned_extract_render_options!(html_options)
      render_options = html_options.delete(:render_options) || {}
      render_options[:locals] = html_options.delete(:locals) if html_options.key?(:locals)
      render_options[:partial] = html_options.delete(:partial) if html_options.key?(:partial)
      render_options[:form_name] = html_options.delete(:form_name) || :f
      render_options
    end

    def cocooned_extract_data!(html_options)
      data = {
        count: [html_options.delete(:count).to_i, 1].compact.max
      }

      limit = html_options.delete(:limit).to_i
      data[:limit] = limit if limit.positive?
      data
    end
  end
end
