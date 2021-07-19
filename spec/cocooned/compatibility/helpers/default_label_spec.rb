# frozen_string_literal: true

# TODO: Remove in 2.0
describe Cocooned::Helpers do
  let(:view) { ActionView::Base.empty }

  describe '#cocooned_default_label' do
    subject(:method) { view.method(:cocooned_default_label) }

    context 'when translations exists in the :cocoon scope' do
      after { I18n.reload! }

      it 'uses custom translations when available' do
        I18n.backend.store_translations(:en, cocoon: { posts: { remove: 'Remove this post' } })
        capture_stderr do
          expect(method.call(:remove, :posts)).to eq('Remove this post')
        end
      end

      it 'uses default translations when not' do
        I18n.backend.store_translations(:en, cocoon: { defaults: { remove: 'Remove' } })
        capture_stderr do
          expect(method.call(:remove, :people)).to eq('Remove')
        end
      end

      it 'emits a warning' do
        I18n.backend.store_translations(:en, cocoon: { defaults: { remove: 'Remove' } })
        expect(capture_stderr { method.call(:remove, :people) }).not_to be_empty
      end
    end
  end
end
