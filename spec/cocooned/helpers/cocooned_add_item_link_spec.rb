# frozen_string_literal: true

describe Cocooned::Helpers do
  let(:view) { ActionView::Base.empty }
  let(:form) { double(object: person, object_name: person.class.name) }
  let(:person) { Person.new }

  describe '#cocooned_add_item_link' do
    subject do
      proc do |*args, &block|
        view.cocooned_add_item_link(*args, &block)
      end
    end

    context 'anytime' do
      before do
        allow(view).to receive(:cocooned_render_association).and_return('<form>')
      end

      it_behaves_like 'a link helper', :add, 3

      it 'has the correct CSS classes' do
        link = parse_link(subject.call('label', form, :posts))

        css_classes = link.attribute('class').value.split(' ')
        expect(css_classes).to include('cocooned-add', 'add_fields')
      end

      it 'supports more CSS classes' do
        link = parse_link(subject.call('label', form, :posts, class: 'another-class'))

        css_classes = link.attribute('class').value.split(' ')
        expect(css_classes).to include('cocooned-add', 'add_fields', 'another-class')
      end

      it 'has correct data-association and data-associations attributes' do
        link = parse_link(subject.call('label', form, :posts))
        expect(link.attribute('data-association').value).to eq('post')
        expect(link.attribute('data-associations').value).to eq('posts')

        link = parse_link(subject.call('label', form, :alumni))
        expect(link.attribute('data-association').value).to eq('alumnus')
        expect(link.attribute('data-associations').value).to eq('alumni')
      end

      it 'has a data-association-template attribute' do
        link = parse_link(subject.call('label', form, :posts))
        expect(link.attribute('data-association-insertion-template').value).to eq('<form>')
      end

      it 'supports more data attributes' do
        link = parse_link(subject.call('label', form, :posts, data: { key: 'value-a' }))
        expect(link.attribute('data-key').value).to eq('value-a')

        link = parse_link(subject.call('label', form, :posts, data_key: 'value-b'))
        expect(link.attribute('data-key').value).to eq('value-b')
      end
    end

    context 'when called with rendering option' do
      shared_examples_for 'an association renderer' do |options = {}|
        it 'forwards it to #cocooned_render_association' do
          expect(view).to receive(:cocooned_render_association)
            .once
            .with(anything, hash_including(options))
            .and_return('<form>')

          subject.call('label', form, :posts, options)
        end
      end

      context ':partial' do
        before do
          # As we test partial rendering, just bypass the form builder
          allow(form).to receive(:fields_for) { |_, _, _, &block| block.call }
        end

        it_behaves_like 'an association renderer', partial: 'partial'

        it 'where it will be correctly used' do
          expect(view).to receive(:render)
            .once
            .with('partial', anything)
            .and_return('<form>')

          subject.call('label', form, :posts, partial: 'partial')
        end

        it 'or use the correct default value' do
          expect(view).to receive(:render)
            .once
            .with('post_fields', anything)
            .and_return('<form>')

          subject.call('label', form, :posts)
        end
      end

      context ':locals' do
        before do
          # As we test partial rendering, just bypass the form builder
          allow(form).to receive(:fields_for) { |_, _, _, &block| block.call }
        end

        it_behaves_like 'an association renderer', locals: { name: 'value' }

        it 'where it will be correctly used' do
          expect(view).to receive(:render)
            .once
            .with(anything, hash_including(name: 'value'))
            .and_return('<form>')

          subject.call('label', form, :posts, locals: { name: 'value' })
        end

        it 'or use the correct default value' do
          expect(view).to receive(:render)
            .once
            .with(anything, hash_excluding(locals: anything))
            .and_return('<form>')

          subject.call('label', form, :posts)
        end
      end

      context ':form_name' do
        before do
          # As we test partial rendering, just bypass the form builder
          allow(form).to receive(:fields_for) { |_, _, _, &block| block.call }
        end

        it_behaves_like 'an association renderer', form_name: 'form'

        it 'where it will be correctly used' do
          expect(view).to receive(:render)
            .once
            .with(anything, hash_including(form: anything))
            .and_return('<form>')

          subject.call('label', form, :posts, form_name: 'form')
        end

        it 'or use the correct default value' do
          expect(view).to receive(:render)
            .once
            .with(anything, hash_including(f: anything))
            .and_return('<form>')

          subject.call('label', form, :posts)
        end
      end

      context ':form_options' do
        it 'is passed to the form builder' do
          expect(form).to receive(:fields_for)
            .with(anything, anything, hash_including(wrapper: 'inline'))
            .and_return('<form>')

          subject.call('label', form, :posts, form_options: { wrapper: 'inline' })
        end
      end
    end

    context 'when called with association option' do
      before do
        allow(view).to receive(:cocooned_render_association).and_return('<form>')
      end

      context ':count' do
        it 'has the correct data attribute' do
          link = parse_link(subject.call('label', form, :posts, count: 2))
          expect(link.attribute('data-count').value.to_i).to eq(2)

          link = parse_link(subject.call('label', form, :posts, data: { count: 2 }))
          expect(link.attribute('data-count').value.to_i).to eq(2)
        end
      end

      context ':insertion_method' do
        it 'has the correct data attribute' do
          link = parse_link(subject.call('label', form, :posts, insertion_method: 'after'))
          expect(link.attribute('data-association-insertion-method').value).to eq('after')

          # Compatibility alternatives
          # TODO: Remove in 3.0
          link = parse_link(subject.call('label', form, :posts, data: { association_insertion_method: 'after-a' }))
          expect(link.attribute('data-association-insertion-method').value).to eq('after-a')

          link = parse_link(subject.call('label', form, :posts, data: { 'association-insertion-method': 'after-b' }))
          expect(link.attribute('data-association-insertion-method').value).to eq('after-b')

          link = parse_link(subject.call('label', form, :posts, data_association_insertion_method: 'after-c'))
          expect(link.attribute('data-association-insertion-method').value).to eq('after-c')

          link = parse_link(subject.call('label', form, :posts, 'data-association-insertion-method': 'after-d'))
          expect(link.attribute('data-association-insertion-method').value).to eq('after-d')

          # Other alternatives
          link = parse_link(subject.call('label', form, :posts, association_insertion_method: 'after-e'))
          expect(link.attribute('data-association-insertion-method').value).to eq('after-e')
        end
      end

      context ':insertion_node' do
        it 'has the correct data attribute' do
          link = parse_link(subject.call('label', form, :posts, insertion_node: '#id'))
          expect(link.attribute('data-association-insertion-node').value).to eq('#id')
        end
      end

      context ':insertion_traversal' do
        it 'has the correct data attribute' do
          link = parse_link(subject.call('label', form, :posts, insertion_traversal: 'children'))
          expect(link.attribute('data-association-insertion-traversal').value).to eq('children')
        end
      end

      context ':wrap_object' do
        it 'passes it to the association builder' do
          expect_any_instance_of(Cocooned::AssociationBuilder).to receive(:options=)
            .with(hash_including(wrap_object: duck_type(:call)))

          parse_link(subject.call('label', form, :posts, wrap_object: ->(i) { i }))
        end
      end

      context ':force_non_association_create' do
        it 'passes it to the association builder' do
          expect_any_instance_of(Cocooned::AssociationBuilder).to receive(:options=)
            .with(hash_including(force_non_association_create: true))

          parse_link(subject.call('label', form, :posts, force_non_association_create: true))
        end
      end
    end
  end
end
