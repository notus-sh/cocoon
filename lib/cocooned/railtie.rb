# frozen_string_literal: true

require 'rails'
require 'cocooned/helpers'

module Cocooned
  class Railtie < ::Rails::Engine
    initializer 'cocooned.initialize' do |_app|
      ActiveSupport.on_load :action_view do
        ActionView::Base.include Cocooned::Helpers
      end
    end
  end
end
