# frozen_string_literal: true

describe Cocooned::Helpers do
  before do
    @view = Class.new(ActionView::Base).new
    @person = Person.new
    @form = double(object: @person, object_name: @person.class.name)
  end

  describe '#cocooned_move_item_up_link' do
    subject do
      proc do |*args, &block|
        @view.cocooned_move_item_up_link(*args, &block)
      end
    end

    it_behaves_like 'a link helper', :up, 2

    it 'has the correct CSS classes' do
      link = parse_link(subject.call('label', @form))

      css_classes = link.attribute('class').value.split(' ')
      expect(css_classes).to include('cocooned-move-up')
    end

    it 'supports more CSS classes' do
      link = parse_link(subject.call('label', @form, class: 'another-class'))

      css_classes = link.attribute('class').value.split(' ')
      expect(css_classes).to include('cocooned-move-up', 'another-class')
    end
  end

  describe '#cocooned_move_item_down_link' do
    subject do
      proc do |*args, &block|
        @view.cocooned_move_item_down_link(*args, &block)
      end
    end

    it_behaves_like 'a link helper', :down, 2

    it 'has the correct CSS classes' do
      link = parse_link(subject.call('label', @form))

      css_classes = link.attribute('class').value.split(' ')
      expect(css_classes).to include('cocooned-move-down')
    end

    it 'supports more CSS classes' do
      link = parse_link(subject.call('label', @form, class: 'another-class'))

      css_classes = link.attribute('class').value.split(' ')
      expect(css_classes).to include('cocooned-move-down', 'another-class')
    end
  end
end
