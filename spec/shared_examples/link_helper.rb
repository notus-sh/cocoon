# frozen_string_literal: true

shared_examples_for 'a link helper' do |action|
  it 'accepts an explicit name as label' do
    arguments = ['label', form, (method.arity == -1 ? :posts : nil)].compact
    link = parse_link(method.call(*arguments))

    expect(link.text).to eq('label')
  end

  it 'can capture a block as label' do
    arguments = [form, (method.arity == -1 ? :posts : nil)].compact
    link = parse_link(method.call(*arguments) { 'label' })

    expect(link.text).to eq('label')
  end

  it 'looks up for translations to use as label if neither an explicit label nor a block is given' do
    allow(I18n).to receive(:translate).and_call_original
    arguments = [form, (method.arity == -1 ? :posts : nil)].compact
    method.call(*arguments)

    expect(I18n).to have_received(:translate).at_least(:once)
  end

  it "uses a default label if nothing's found" do
    arguments = [form, (method.arity == -1 ? :posts : nil)].compact
    link = parse_link(method.call(*arguments))

    expect(link.text).to eq(action.to_s.humanize)
  end

  it 'has an empty href' do
    arguments = ['label', form, (method.arity == -1 ? :posts : nil)].compact
    link = parse_link(method.call(*arguments))

    expect(link.attribute('href').value).to eq('#')
  end

  it 'pass additional options to link_to' do
    arguments = ['label', form, (method.arity == -1 ? :posts : nil), { rel: 'no-follow' }].compact
    link = parse_link(method.call(*arguments))

    expect(link.attribute('rel').value).to eq('no-follow')
  end

  it 'does not alter options' do
    arguments = ['label', form, (method.arity == -1 ? :posts : nil), { class: 'specific-class' }].compact
    method.call(*arguments)

    expect(arguments.last[:class]).to eq('specific-class')
  end
end
