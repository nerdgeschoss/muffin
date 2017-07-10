module Muffin
  module Execution
    def call
      call!
      true
    rescue
      false
    end

    def call!
      validate!
      perform if respond_to? :perform
    end
  end
end
