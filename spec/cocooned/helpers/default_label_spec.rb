# frozen_string_literal: true

describe Cocooned::Helpers do
  let(:view) { ActionView::Base.empty }

  describe '#cocooned_default_label' do
    subject(:method) { view.method(:cocooned_default_label) }

    context 'when translations exist in the :cocooned scope' do
      after { I18n.reload! }

      it 'uses custom translations when available' do
        I18n.backend.store_translations(:en, cocooned: { posts: { remove: 'Remove this post' } })
        expect(method.call(:remove, :posts)).to eq('Remove this post')
      end

      it 'uses default translations when not' do
        I18n.backend.store_translations(:en, cocooned: { defaults: { remove: 'Remove' } })
        expect(method.call(:remove, :people)).to eq('Remove')
      end
    end

    context 'when no translation exist' do
      it 'returns the humanized name of the action' do
        expect(method.call(:remove, :posts)).to eq('Remove')
      end
    end
  end
end
