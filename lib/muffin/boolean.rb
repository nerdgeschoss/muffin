module Muffin
  class Boolean
    def initialize(value)
      @value = value
    end

    attr_reader :value

    def to_bool
      case value
      when nil
        nil
      when "0", "false"
        false
      else
        !!value
      end
    end
  end
end
