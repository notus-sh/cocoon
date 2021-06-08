# frozen_string_literal: true

describe Cocooned::Helpers do
  describe '#cocooned_default_label' do
    subject(:tester) { ActionView::Base.empty }

    after { I18n.reload! }

    context 'using the :cocooned i18n scope' do
      before do
        I18n.backend.store_translations(:en, cocooned: {
                                          defaults: { remove: 'Remove' },
                                          posts: { remove: 'Remove this post' }
                                        })
      end

      it 'uses custom translations when available' do
        expect(tester.send(:cocooned_default_label, :remove, :posts)).to eq('Remove this post')
      end

      it 'uses default translations when not' do
        expect(tester.send(:cocooned_default_label, :remove, :people)).to eq('Remove')
      end
    end

    context 'when no translation exist' do
      it 'returns the humanized name of the action' do
        expect(tester.send(:cocooned_default_label, :remove, :posts)).to eq('Remove')
      end
    end
  end
end
