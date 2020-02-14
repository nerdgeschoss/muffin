module Muffin
  module Type
    class Hash
      def deserialize(value)
        return JSON.parse(value) if value.is_a?(String)
        value&.to_h
      end
    end
  end
end
