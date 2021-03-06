# frozen_string_literal: true

# Cocoon compatibility
# TODO: Remove in 2.0

describe Cocooned::Railtie do
  subject { Class.new(ActionView::Base).new }

  it { is_expected.to respond_to(:link_to_add_association) }
  it { is_expected.to respond_to(:link_to_remove_association) }
end

describe Cocooned::Helpers do
  before(:each) do
    @tester = Class.new(ActionView::Base).new
  end

  describe '#cocooned_default_label' do
    after(:each) do
      I18n.reload!
    end

    context 'using the :cocoon i18n scope' do
      before(:each) do
        allow(self).to receive(:warn)
        I18n.backend.store_translations(:en, cocoon: {
                                          defaults: { remove: 'Remove' },
                                          posts: { remove: 'Remove this post' }
                                        })
      end

      it 'should use custom translations when available' do
        capture_stderr do
          expect(@tester.send(:cocooned_default_label, :remove, :posts)).to eq('Remove this post')
        end
      end

      it 'should use default translations when not' do
        capture_stderr do
          expect(@tester.send(:cocooned_default_label, :remove, :people)).to eq('Remove')
        end
      end

      it 'should emit a warning' do
        expect(capture_stderr { @tester.send(:cocooned_default_label, :remove, :people) }).not_to be_empty
      end
    end
  end
end

describe Cocooned::Helpers do
  before(:each) do
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

    context 'when called with compatibility option' do
      context ':render_options' do
        it 'should be passed to the form builder' do
          expect(@form).to receive(:fields_for)
            .with(anything, anything, hash_including(wrapper: 'inline'))
            .and_return('<form>')

          capture_stderr do
            subject.call('label', @form, :posts, render_options: { wrapper: 'inline' })
          end
        end

        it 'should emit a warning' do
          # Just bypass the complete association rendering, as options extraction already
          # occured when it's called.
          allow(@view).to receive(:cocooned_render_association).and_return('<form>')

          output = capture_stderr do
            subject.call('label', @form, :posts, render_options: { wrapper: 'inline' })
          end
          expect(output).not_to be_empty
        end
      end

      context ':render_options with a :locals key' do
        before(:each) do
          # As we test partial rendering, just bypass the form builder
          allow(@form).to receive(:fields_for) { |_, _, _, &block| block.call }
        end

        it 'should forward it to #cocooned_render_association' do
          expect(@view).to receive(:cocooned_render_association)
            .once
            .with(anything, hash_including(locals: { name: 'value' }))
            .and_return('<form>')

          capture_stderr do
            subject.call('label', @form, :posts, render_options: { locals: { name: 'value' } })
          end
        end
      end
    end
  end
end
