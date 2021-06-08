# frozen_string_literal: true

describe Cocooned::Helpers do
  let(:view) { ActionView::Base.empty }
  let(:form) { ActionView::Base.default_form_builder.new(person.class.name, person, view, {}) }
  let(:person) { Person.new }

  describe '#cocooned_remove_item_link' do
    subject do
      proc do |*args, &block|
        view.cocooned_remove_item_link(*args, &block)
      end
    end

    it_behaves_like 'a link helper', :remove, 2

    it 'has the correct CSS classes' do
      link = parse_link(subject.call('label', form))

      css_classes = link.attribute('class').value.split(' ')
      expect(css_classes).to include('cocooned-remove', 'remove_fields')
    end

    it 'wears a .dynamic CSS classe for new record' do
      expect(person).to receive(:new_record?).at_least(:once).and_return(true)
      link = parse_link(subject.call('label', form))

      css_classes = link.attribute('class').value.split(' ')
      expect(css_classes).to include('dynamic')
      expect(css_classes).not_to include('existing', 'destroyed')
    end

    it 'wears an .existing CSS classe for saved record' do
      expect(person).to receive(:new_record?).at_least(:once).and_return(false)
      link = parse_link(subject.call('label', form))

      css_classes = link.attribute('class').value.split(' ')
      expect(css_classes).to include('existing')
      expect(css_classes).not_to include('dynamic', 'destroyed')
    end

    it 'wears an .destroyed CSS classe for record marked for destruction' do
      expect(person).to receive(:marked_for_destruction?).at_least(:once).and_return(true)
      link = parse_link(subject.call('label', form))
      css_classes = link.attribute('class').value.split(' ')
      expect(css_classes).to include('destroyed')
    end

    it 'supports more CSS classes' do
      link = parse_link(subject.call('label', form, class: 'another-class'))

      css_classes = link.attribute('class').value.split(' ')
      expect(css_classes).to include('cocooned-remove', 'remove_fields', 'another-class')
    end

    it 'also output a _destroy hidden field' do
      html = parse_html(subject.call('label', form))

      expect(html.css('input[type="hidden"][name$="[_destroy]"]')).not_to be_empty
    end
  end
end
