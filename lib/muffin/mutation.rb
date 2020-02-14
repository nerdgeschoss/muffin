module Muffin
  class Mutation < Base
    attr_reader :model

    def initialize(model:, request: nil, params: nil, scope: nil)
      @model = model
      assign_model
      super request: request, params: params, scope: scope
    end

    def assign_model
      self.class.attributes.keys.each do |key|
        public_send("#{key}=", model.public_send(key)) if model.respond_to?(key)
      end
    end

    def perform
      self.class.attributes.keys.each do |key|
        model.public_send("#{key}=", public_send(key)) if model.respond_to?(key)
      end
      model.save!
    end

    def persisted?
      model.present?
    end
  end
end
