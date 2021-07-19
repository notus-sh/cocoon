# frozen_string_literal: true

# TODO: Remove in 2.0
describe Cocooned::Railtie do
  subject(:view) { ActionView::Base.empty }

  it { is_expected.to respond_to(:link_to_add_association) }
  it { is_expected.to respond_to(:link_to_remove_association) }
end
