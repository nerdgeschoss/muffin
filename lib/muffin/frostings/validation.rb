require "active_model"

module Muffin
  module Validation
    def self.included(base)
      base.include ActiveModel::Validations
    end
  end
end
