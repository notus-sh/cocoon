# frozen_string_literal: true

describe Cocooned::Railtie do
  subject { Class.new(ActionView::Base).new }

  it { is_expected.to respond_to(:cocooned_add_item_link) }
  it { is_expected.to respond_to(:cocooned_remove_item_link) }
end
