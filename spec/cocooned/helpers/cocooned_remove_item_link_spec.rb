# frozen_string_literal: true

describe Cocooned::Helpers do
  let(:view) { ActionView::Base.empty }
  let(:form) { ActionView::Base.default_form_builder.new(person.class.name, person, view, {}) }
  let(:person) { Person.new }

  describe '#cocooned_remove_item_link' do
    subject(:method) { view.method(:cocooned_remove_item_link) }

    it_behaves_like 'a link helper', :remove

    it 'has the correct CSS classes' do
      link = parse_link(method.call('label', form))
      css_classes = link.attribute('class').value.split(' ')

      expect(css_classes).to include('cocooned-remove', 'remove_fields')
    end

    it 'wears a .dynamic CSS classe for new record' do
      allow(person).to receive(:new_record?).at_least(:once).and_return(true)
      link = parse_link(method.call('label', form))
      css_classes = link.attribute('class').value.split(' ')

      expect(css_classes).to include('dynamic')
    end

    it 'wears only a .dynamic CSS classe for new record' do
      allow(person).to receive(:new_record?).at_least(:once).and_return(true)
      link = parse_link(method.call('label', form))
      css_classes = link.attribute('class').value.split(' ')

      expect(css_classes).not_to include('existing', 'destroyed')
    end

    it 'wears an .existing CSS classe for saved record' do
      allow(person).to receive(:new_record?).at_least(:once).and_return(false)
      link = parse_link(method.call('label', form))
      css_classes = link.attribute('class').value.split(' ')

      expect(css_classes).to include('existing')
    end

    it 'wears only an .existing CSS classe for saved record' do
      allow(person).to receive(:new_record?).at_least(:once).and_return(false)
      link = parse_link(method.call('label', form))
      css_classes = link.attribute('class').value.split(' ')

      expect(css_classes).not_to include('dynamic', 'destroyed')
    end

    it 'wears an .destroyed CSS classe for record marked for destruction' do
      allow(person).to receive(:marked_for_destruction?).at_least(:once).and_return(true)
      link = parse_link(method.call('label', form))
      css_classes = link.attribute('class').value.split(' ')

      expect(css_classes).to include('destroyed')
    end

    it 'supports more CSS classes' do
      link = parse_link(method.call('label', form, class: 'another-class'))
      css_classes = link.attribute('class').value.split(' ')

      expect(css_classes).to include('cocooned-remove', 'remove_fields', 'another-class')
    end

    it 'also output a _destroy hidden field' do
      html = parse_html(method.call('label', form))

      expect(html.css('input[type="hidden"][name$="[_destroy]"]')).not_to be_empty
    end
  end
end
