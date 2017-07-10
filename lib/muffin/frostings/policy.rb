module Muffin
  module Policy
    module ClassMethods
      def permitted?(&block)
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end
  end
end
