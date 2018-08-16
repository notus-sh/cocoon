# frozen_string_literal: true

require 'cocooned/helpers/deprecate'
require 'cocooned/helpers/cocoon_compatibility'

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

    # shows a link that will allow to dynamically add a new associated object.
    #
    # - *name* :         the text to show in the link
    # - *form* :            the form this should come in (the formtastic form)
    # - *association* :  the associated objects, e.g. :tasks, this should be the name of the <tt>has_many</tt> relation.
    # - *html_options*:  html options to be passed to <tt>link_to</tt> (see <tt>link_to</tt>)
    #          - *:render_options* : options passed to `simple_fields_for, semantic_fields_for or fields_for`
    #              - *:locals*     : the locals hash in the :render_options is handed to the partial
    #          - *:partial*        : explicitly override the default partial name
    #          - *:wrap_object*    : a proc that will allow to wrap your object, especially suited when using
    #                                decorators, or if you want special initialisation
    #          - *:form_name*      : the parameter for the form in the nested form partial. Default `f`.
    #          - *:count*          : Count of how many objects will be added on a single click. Default `1`.
    # - *&block*:        see <tt>link_to</tt>
    def cocooned_add_item_link(*args, &block)
      if block_given?
        cocooned_add_item_link(capture(&block), *args)

      elsif args.first.respond_to?(:object)
        association = args.second
        cocooned_add_item_link(cocooned_default_label(:add, association), *args)

      else
        name, form, association, html_options = *args
        html_options ||= {}

        render_options   = html_options.delete(:render_options)
        render_options ||= {}
        override_partial = html_options.delete(:partial)
        wrap_object = html_options.delete(:wrap_object)
        force_non_association_create = html_options.delete(:force_non_association_create) || false
        form_parameter_name = html_options.delete(:form_name) || 'f'
        count = html_options.delete(:count).to_i
        limit = html_options.delete(:limit).to_i

        html_options[:class] = [html_options[:class], Cocooned::HELPER_CLASSES[:add]].flatten.compact.join(' ')
        html_options[:'data-association'] = association.to_s.singularize
        html_options[:'data-associations'] = association.to_s.pluralize

        new_object = create_object(form, association, force_non_association_create)
        new_object = wrap_object.call(new_object) if wrap_object.respond_to?(:call)

        rendered = render_association(association,
                                      form,
                                      new_object,
                                      form_parameter_name,
                                      render_options,
                                      override_partial)
        content = CGI.escapeHTML(rendered.to_str).html_safe

        html_options[:'data-association-insertion-template'] = content
        html_options[:'data-wrapper-class'] = /(?<=class=["'])[^"^']*(?=["'])/.match(content)

        html_options[:'data-count'] = count if count.positive?
        html_options[:'data-limit'] = limit if limit.positive?

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

    # creates new association object with its conditions, like
    # `` has_many :admin_comments, class_name: "Comment", conditions: { author: "Admin" }
    # will create new Comment with author "Admin"
    def create_object(form, association, force_non_association_create = false)
      klass = form.object.class
      assoc = klass.respond_to?(:reflect_on_association) ? klass.reflect_on_association(association) : nil

      return create_object_on_association(form, association, assoc, force_non_association_create) if assoc
      create_object_on_non_association(form, association)
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

    # :nodoc:
    def render_association(association, form, new_object, form_name, render_options = {}, custom_partial = nil)
      partial = custom_partial || association.to_s.singularize + '_fields'
      locals =  render_options.delete(:locals) || {}
      ancestors = form.class.ancestors.map(&:to_s)
      method_name = if ancestors.include?('SimpleForm::FormBuilder')
                      :simple_fields_for
                    elsif ancestors.include?('Formtastic::FormBuilder')
                      :semantic_fields_for
                    else
                      :fields_for
                    end

      form.send(method_name, association, new_object, { child_index: "new_#{association}" }.merge(render_options)) do |builder|
        partial_options = { form_name.to_sym => builder, :dynamic => true }.merge(locals)
        render(partial, partial_options)
      end
    end

    def create_object_on_non_association(form, association)
      builder_method = %W[build_#{association} build_#{association.to_s.singularize}].select { |m| form.object.respond_to?(m) }.first
      return form.object.send(builder_method) if builder_method
      raise "Association #{association} doesn't exist on #{form.object.class}"
    end

    def create_object_on_association(form, association, instance, force_non_association_create)
      if instance.class.name == 'Mongoid::Relations::Metadata' || force_non_association_create
        create_object_with_conditions(instance)
      else
        # assume ActiveRecord or compatible
        if instance.collection?
          assoc_obj = form.object.send(association).build
          form.object.send(association).delete(assoc_obj)
        else
          assoc_obj = form.object.send("build_#{association}")
          form.object.send(association).delete
        end

        assoc_obj = assoc_obj.dup if assoc_obj.frozen?
        assoc_obj
      end
    end

    def create_object_with_conditions(instance)
      # in rails 4, an association is defined with a proc
      # and I did not find how to extract the conditions from a scope
      # except building from the scope, but then why not just build from the
      # association???
      conditions = instance.respond_to?(:conditions) ? instance.conditions.flatten : []
      instance.klass.new(*conditions)
    end
  end
end
