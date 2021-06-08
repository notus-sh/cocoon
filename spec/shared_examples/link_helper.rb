# frozen_string_literal: true

shared_examples_for 'a link helper' do |action, arity|
  it 'accepts an explicit name as label' do
    arguments = ['label', form]
    arguments << :posts if arity == 3

    link = parse_link(subject.call(*arguments))
    expect(link.text).to eq('label')
  end

  it 'can capture a block as label' do
    arguments = [form]
    arguments << :posts if arity == 3

    link = parse_link(subject.call(*arguments) { 'label' })
    expect(link.text).to eq('label')
  end

  it 'look up for translations to use as label if neither an explicit label nor a block is given' do
    expect(I18n).to receive(:translate).at_least(:once).and_call_original

    arguments = [form]
    arguments << :posts if arity == 3

    link = parse_link(subject.call(*arguments))
    expect(link.text).to eq(action.to_s.humanize)
  end

  it 'has an empty href' do
    arguments = ['label', form]
    arguments << :posts if arity == 3

    link = parse_link(subject.call(*arguments))
    expect(link.attribute('href').value).to eq('#')
  end

  it 'pass additional options to link_to' do
    arguments = ['label', form]
    arguments << :posts if arity == 3
    arguments << { rel: 'no-follow', hreflang: :en }

    link = parse_link(subject.call(*arguments))
    expect(link.attribute('rel').value).to eq('no-follow')
    expect(link.attribute('hreflang').value).to eq('en')
  end

  it 'does not alter options' do
    arguments = ['label', form]
    arguments << :posts if arity == 3
    arguments << { class: 'specific-class' }

    subject.call(*arguments)
    expect(arguments.last[:class]).to eq('specific-class')
  end
end
