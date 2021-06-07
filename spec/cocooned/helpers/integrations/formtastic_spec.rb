# frozen_string_literal: true

describe Cocooned::Helpers do
  before do
    @view = Class.new(ActionView::Base).new
    @person = Person.new
    @form = double(object: @person, object_name: @person.class.name)
  end

  describe '#cocooned_add_item_link' do
    subject do
      proc do |*args, &block|
        @view.cocooned_add_item_link(*args, &block)
      end
    end

    context 'with formtastic' do
      before do
        allow(@form).to receive_message_chain(:class, :ancestors) { ['Formtastic::FormBuilder'] }
        expect(@form).to receive(:semantic_fields_for).and_return('<form>')
        expect(@form).not_to receive(:fields_for)
      end

      it_behaves_like 'a link helper', :add, 3
    end
  end
end
