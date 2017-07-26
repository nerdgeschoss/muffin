require "action_view"

module Muffin
  class MockView
    attr_accessor :output_buffer

    include ActionView::Helpers::CsrfHelper
    include ActionView::Helpers::FormHelper

    def polymorphic_path(*_args)
      "/"
    end

    def protect_against_forgery?
      false
    end
  end
end
