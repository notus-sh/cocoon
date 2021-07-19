# frozen_string_literal: true

require 'cocooned/helpers/deprecate'
require 'cocooned/helpers/cocoon_compatibility'
require 'cocooned/association_builder'

module Cocooned
  # TODO: Remove in 3.0 (Only Cocoon class names).
  HELPER_CLASSES = {
    add: %w[cocooned-add add_fields],
    remove: %w[cocooned-remove remove_fields],
    up: %w[cocooned-move-up],
    down: %w[cocooned-move-down]
  }.freeze

  module Helpers # rubocop:disable Metrics/ModuleLength
    # Create aliases to old Cocoon method name
    # TODO: Remove in 3.0
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
    # ==== Parameters
    #
    # `label` is the text to be used as the link label.
    # Just as when you use the Rails builtin helper +link_to+, you can give an explicit
    # label to your link or use a block to build it.
    # If you provide neither an explicit label nor a block, Cocooned will try to use I18n
    # to find a suitable label. This lookup will check the following keys:
    #
    # - `cocooned.{association}.add`
    # - `cocooned.defaults.add`
    #
    # If none of these translation exist, it will fallback to 'Add'.
    #
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
    # - **form_options**: options to be passed to the nested form builder. Can be used
    #   to specify a wrapper for simple_form_fields if you use its Bootstrap setup, for
    #   example.
    #   No defaults.
    # - **locals**: a hash of local variables, will be forwarded to the partial.
    #   No default.
    #
    # Association options:
    #
    # - **insertion_method** : the jQuery method to be used to insert new items.
    #   Can be any of `before`, `after`, `append`, `prepend`, `replaceWith`.
    #   Defaults to `before`
    # - **insertion_traversal** and **insertion_node** : respectively the jQuery
    #   traversal method and the jQuery compatible selector that will be used to find
    #   the insertion node, relative to the generated link.
    #   When both are specified, `$(addLink).{traversal}({node})` will be used.
    #   When only **insertion_node** is specified, `$({node})` will be used.
    #   When only **insertion_traversal** is specified, it will be ignored.
    #   When none is specified, `$(addLink).parent()` will be used.
    # - **count**: how many item will be inserted on click.
    #   Defaults to 1.
    # - **wrap_object**: anything responding to `call` to be used to wrap the newly build
    #   item instance. Can be useful with decorators or special initialisations.
    #   Ex: cocooned_add_item_link "Add an item", form, :items,
    #         wrap_object: Proc.new { |comment| CommentDecorator.new(comment) })
    #   No default.
    # - **force_non_association_create**: force to build instances of the nested model
    #   outside association (i.e. without calling `build_{association}` or `{association}.build`)
    #   Can be usefull if, for some specific reason, you need an object to _not_ be created
    #   on the association, for example if you did not want `after_add` callbacks to be triggered.
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
    # - **render_options**: A nested Hash originaly used to pass locals and form builder
    #   options.
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
        html_options = html_options.dup.with_indifferent_access

        builder_options = cocooned_extract_builder_options!(html_options)
        render_options = cocooned_extract_render_options!(html_options)

        builder = Cocooned::AssociationBuilder.new(form, association, builder_options)
        rendered = cocooned_render_association(builder, render_options)

        data = cocooned_extract_data!(html_options).merge!(
          association: builder.singular_name,
          associations: builder.plural_name,
          association_insertion_template: CGI.escapeHTML(rendered.to_str).html_safe
        )

        html_options[:data] = (html_options[:data] || {}).merge(data)
        html_options[:class] = [Array(html_options.delete(:class)).collect { |k| k.to_s.split(' ') },
                                Cocooned::HELPER_CLASSES[:add]].flatten.compact.uniq.join(' ')

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

      link_options = html_options.dup
      link_options[:class] = [html_options[:class], Cocooned::HELPER_CLASSES[:remove]].flatten.compact
      link_options[:class] << (form.object.new_record? ? 'dynamic' : 'existing')
      link_options[:class] << 'destroyed' if form.object.marked_for_destruction?

      form.hidden_field(:_destroy, value: form.object._destroy) << link_to(name, '#', link_options)
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

      link_options = html_options.dup
      link_options[:class] = [html_options[:class], Cocooned::HELPER_CLASSES[direction]].flatten.compact.join(' ')
      link_to name, '#', link_options
    end

    def cocooned_default_label(action, association = nil)
      # TODO: Remove in 3.0
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

    def cocooned_render_association(builder, options = {})
      render_options = options.dup
      locals = (render_options.delete(:locals) || {}).symbolize_keys
      partial = render_options.delete(:partial) || "#{builder.singular_name}_fields"
      form_name = render_options.delete(:form_name)
      form_options = (render_options.delete(:form_options) || {}).symbolize_keys
      form_options.reverse_merge!(child_index: "new_#{builder.association}")

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
      render_options = { form_name: :f }

      # TODO: Remove in 2.0
      if html_options.key?(:render_options)
        msg = Cocooned::Helpers::Deprecate.deprecate_release_message(':render_options', :none)
        warn msg

        options = html_options.delete(:render_options)
        render_options[:locals] = options.delete(:locals) if options.key?(:locals)
        render_options[:form_options] = options
      end

      %i[locals partial form_name form_options].each_with_object(render_options) do |option_name, opts|
        opts[option_name] = html_options.delete(option_name) if html_options.key?(option_name)
      end
    end

    def cocooned_extract_data!(html_options)
      data = {
        count: [
          html_options.delete(:count).to_i,
          (html_options.key?(:data) ? html_options[:data].delete(:count) : 0).to_i,
          1
        ].compact.max,
        association_insertion_node: cocooned_extract_single_data!(html_options, :insertion_node),
        association_insertion_method: cocooned_extract_single_data!(html_options, :insertion_method),
        association_insertion_traversal: cocooned_extract_single_data!(html_options, :insertion_traversal)
      }

      # Compatibility with the old way to pass data attributes to Rails view helpers
      # Has we build a :data key, they will not be looked up.
      html_options.keys.select { |k| k.to_s.match?(/data[_-]/) }.each_with_object(data) do |data_key, d|
        key = data_key.to_s.gsub(/^data[_-]/, '')
        d[key] = html_options.delete(data_key)
      end
      data.compact
    end

    def cocooned_extract_single_data!(hash, key)
      k = key.to_s
      return hash.delete(k) if hash.key?(k)

      # Compatibility alternatives
      # TODO: Remove in 2.0
      return hash.delete("association_#{k}") if hash.key?("association_#{k}")
      return hash.delete("data_association_#{k}") if hash.key?("data_association_#{k}")
      return hash.delete("data-association-#{k.tr('_', '-')}") if hash.key?("data-association-#{k.tr('_', '-')}")
      return nil unless hash.key?(:data)

      d = hash[:data].with_indifferent_access
      return d.delete("association_#{k}") if d.key?("association_#{k}")
      return d.delete("association-#{k.tr('_', '-')}") if d.key?("association-#{k.tr('_', '-')}")

      nil
    end
  end
end
