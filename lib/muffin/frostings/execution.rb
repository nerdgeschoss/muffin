module Muffin
  module Execution
    def call
      return false unless valid?

      permit!
      perform if respond_to? :perform
      true
    end

    def call!
      validate!
      permit!
      perform if respond_to? :perform
    end
  end
end
