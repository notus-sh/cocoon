# frozen_string_literal: true

describe Cocooned::AssociationBuilder do
  describe '#build_object' do
    it 'creates correct association for belongs_to associations' do
      post = Post.new
      form = double(object: post)
      builder = described_class.new(form, :author)
      result = builder.build_object

      expect(result).to be_a Person
      expect(post.author).to be_nil
    end

    it 'creates correct association with conditions' do
      person = Person.new
      form = double(object: person)
      builder = described_class.new(form, :alumni)
      result = builder.build_object

      expect(result).to be_a Person
      expect(result.status).to eq('student')
      expect(person.alumni).to be_empty
    end

    it 'creates correct association for has_one associations' do
      person = Person.new
      form = double(object: person)
      builder = described_class.new(form, :biography)
      result = builder.build_object

      expect(result).to be_a Post
      expect(person.biography).to be_nil
    end

    it 'creates correct association for has_many associations' do
      person = Person.new
      form = double(object: person)
      builder = described_class.new(form, :posts)
      result = builder.build_object

      expect(result).to be_a Post
      expect(person.posts).to be_empty
    end

    it 'creates correct association for has_and_belongs_to_many associations' do
      person = Person.new
      form = double(object: person)
      builder = described_class.new(form, :contacts)
      result = builder.build_object

      expect(result).to be_a Person
      expect(person.contacts).to be_empty
    end

    it 'creates an object if cannot reflect on association' do
      object = double('AnyNonActiveRecordObject')
      form = double(object: object)
      builder = described_class.new(form, :non_reflectable)

      expect(object).to receive(:build_non_reflectable).and_return 'custom'
      result = builder.build_object
      expect(result).to eq('custom')
    end

    context "if object respond to 'build_association'" do
      subject do
        Class.new(Post) do
          def build_custom_item; end
        end
      end

      it 'creates an association as singular' do
        object = subject.new
        form = double(object: object)
        builder = described_class.new(form, :custom_item)

        expect(object).to receive(:build_custom_item).and_return('custom')
        result = builder.build_object
        expect(result).to eq('custom')
      end

      it 'creates an association as plural' do
        object = subject.new
        form = double(object: object)
        builder = described_class.new(form, :custom_items)

        expect(object).to receive(:build_custom_item).and_return('custom')
        result = builder.build_object
        expect(result).to eq('custom')
      end
    end

    it 'can create using only conditions not the association' do
      person = Person.new
      form = double(object: person)
      builder = described_class.new(form, :alumni, force_non_association_create: true)

      expect(builder).to receive(:build_with_conditions).and_return('flappie')
      result = builder.build_object
      expect(result).to eq('flappie')
    end

    it 'can wrap object' do
      person = Person.new
      form = double(object: person)
      builder = described_class.new(form, :posts, wrap_object: proc { |p| PostDecorator.new(p) })

      result = builder.build_object
      expect(result).to be_a(PostDecorator)
    end
  end
end
