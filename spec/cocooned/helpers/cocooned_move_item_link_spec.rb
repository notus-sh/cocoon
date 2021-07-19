# frozen_string_literal: true

describe Cocooned::Helpers do
  let(:view) { ActionView::Base.empty }
  let(:form) { double(object: person, object_name: person.class.name) }
  let(:person) { Person.new }

  describe '#cocooned_move_item_up_link' do
    subject(:method) { view.method(:cocooned_move_item_up_link) }

    it_behaves_like 'a link helper', :up

    it 'has the correct CSS classes' do
      link = parse_link(method.call('label', form))
      css_classes = link.attribute('class').value.split(' ')

      expect(css_classes).to include('cocooned-move-up')
    end

    it 'supports more CSS classes' do
      link = parse_link(method.call('label', form, class: 'another-class'))
      css_classes = link.attribute('class').value.split(' ')

      expect(css_classes).to include('cocooned-move-up', 'another-class')
    end
  end

  describe '#cocooned_move_item_down_link' do
    subject(:method) { view.method(:cocooned_move_item_down_link) }

    it_behaves_like 'a link helper', :down

    it 'has the correct CSS classes' do
      link = parse_link(method.call('label', form))
      css_classes = link.attribute('class').value.split(' ')

      expect(css_classes).to include('cocooned-move-down')
    end

    it 'supports more CSS classes' do
      link = parse_link(method.call('label', form, class: 'another-class'))
      css_classes = link.attribute('class').value.split(' ')

      expect(css_classes).to include('cocooned-move-down', 'another-class')
    end
  end
end
