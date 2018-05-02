module Muffin
  module Rails
    SCOPE_ACCESSOR = :operation_auth_scope

    module ControllerAdditions
      def prepare(operation, params: nil, request: nil, scope: nil)
        if params.blank? && respond_to?(:params) && operation.respond_to?(:model_name)
          if self.params.key?(operation.model_name.param_key)
            params = parse_arrays self.params[operation.model_name.param_key].deep_dup.permit!.to_h
            params.deep_transform_keys! do |key|
              if key.to_s[/.+_attributes\Z/]
                new_key = key.to_s.sub(/_attributes\Z/, "")
                key.is_a?(Symbol) ? new_key.to_sym : new_key
              else
                key
              end
            end
          end
        end

        request ||= try(:request)

        scope ||= try(Muffin::Rails::SCOPE_ACCESSOR) || try(:current_user)

        operation.new(params: params, request: request, scope: scope)
      end

      private

      def parse_arrays(obj)
        obj.each do |key, value|
          if value.is_a? Hash
            if value.keys.find { |k, _| k =~ /\D/ }
              parse_arrays(value)
            else
              obj[key] = value.values
              value.each_value { |h| parse_arrays(h) }
            end
          end
        end
      end
    end
  end
end
