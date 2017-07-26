require "active_model"

module Muffin
  module Validation
    class NestedAttributesValidator < ActiveModel::Validator
      def validate(entity)
        entity.attributes.try(:each) do |k, v|
          Array.wrap(v).each do |e|
            if e.is_a?(Muffin::NestedAttribute)
              e.validate
              entity.errors[k] << :nested_validation_failed if e.errors.present?
            end
          end
        end
      end
    end

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
