module Muffin
  module Execution
    def self.included(base)
      base.extend ActiveModel::Callbacks
      base.define_model_callbacks :call
    end

    def call
      run_callbacks :call do
        return false unless valid?
        permit!
        perform if respond_to? :perform
        true
      end
    end

    def call!
      run_callbacks :call do
        validate!
        permit!
        perform if respond_to? :perform
      end
    end
  end
end
