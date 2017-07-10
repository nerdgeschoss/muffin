require "active_model"

module Muffin
  module Validation
    def self.included(base)
      base.include ActiveModel::Validations
    end

    def required_attributes
      @required_attributes ||= self.class.validators
        .select { |e| e.is_a? ActiveModel::Validations::PresenceValidator }
        .flat_map(&:attributes)
        .uniq
    end
  end
end
