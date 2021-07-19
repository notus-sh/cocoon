# frozen_string_literal: true

# TODO: Remove in 2.0
describe Cocooned::Helpers do
  let(:view) { ActionView::Base.empty }
  let(:form) { double(object: person, object_name: person.class.name) }
  let(:person) { Person.new }

  describe '#cocooned_add_item_link' do
    subject(:method) { view.method(:cocooned_add_item_link) }

    context 'when called with compatibility option' do
      context 'with :render_options' do
        it 'is passed to the form builder' do # rubocop:disable RSpec/ExampleLength
          expect(form).to receive(:fields_for)
            .with(anything, anything, hash_including(wrapper: 'inline'))
            .and_return('<form>')

          capture_stderr do
            method.call('label', form, :posts, render_options: { wrapper: 'inline' })
          end
        end

        it 'emits a warning' do
          # Just bypass the complete association rendering, as options extraction already
          # occured when it's called.
          allow(view).to receive(:cocooned_render_association).and_return('<form>')

          output = capture_stderr do
            method.call('label', form, :posts, render_options: { wrapper: 'inline' })
          end
          expect(output).not_to be_empty
        end
      end

      context 'with :render_options and a :locals key' do
        before do
          # As we test partial rendering, just bypass the form builder
          allow(form).to receive(:fields_for) { |_, _, _, &block| block.call }
        end

        it 'forwards it to #cocooned_render_association' do # rubocop:disable RSpec/ExampleLength
          expect(view).to receive(:cocooned_render_association)
            .once
            .with(anything, hash_including(locals: { name: 'value' }))
            .and_return('<form>')

          capture_stderr do
            method.call('label', form, :posts, render_options: { locals: { name: 'value' } })
          end
        end
      end
    end
  end
end
