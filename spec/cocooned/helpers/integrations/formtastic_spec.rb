# frozen_string_literal: true

describe Cocooned::Helpers do
  let(:view) { ActionView::Base.empty }
  let(:form) { double(object: person, object_name: person.class.name) }
  let(:person) { Person.new }

  describe '#cocooned_add_item_link' do
    subject(:method) { view.method(:cocooned_add_item_link) }

    context 'with formtastic' do
      before do
        allow(form).to receive_message_chain(:class, :ancestors) { ['Formtastic::FormBuilder'] }
        allow(form).to receive(:semantic_fields_for).and_return('<form>')
      end

      it_behaves_like 'a link helper', :add

      it 'does not call #fields_for' do
        allow(form).to receive(:fields_for)
        arguments = ['label', form, (method.arity == -1 ? :posts : nil)].compact
        method.call(*arguments)

        expect(form).not_to have_received(:fields_for)
      end
    end
  end
end
