module Muffin
  module Type
    class DateTime
      def deserialize(value)
        return value if value.is_a?(DateTime)

        value && Time.zone.parse(value.to_s)&.to_datetime
      end
    end
  end
end
