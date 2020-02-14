module Muffin
  module Type
    class Symbol
      def deserialize(value)
        value&.to_s&.to_sym
      end
    end
  end
end
