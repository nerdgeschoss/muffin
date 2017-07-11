module Muffin
  module Rails
    SCOPE_ACCESSOR = :operation_auth_scope

    module ControllerAdditions
      def prepare(operation, params: nil, request: nil, scope: nil)
        if params.blank? && respond_to?(:params) && operation.respond_to?(:model_name)
          if self.params.key?(operation.model_name.underscore)
            params = self.params[operation.model_name.underscore].deep_dup.permit!.to_h
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

        request = self.request if request.blank? && respond_to?(:request)

        if scope.blank?
          scope = begin
            if respond_to?(Muffin::Rails::SCOPE_ACCESSOR)
              send(Muffin::Rails::SCOPE_ACCESSOR)
            elsif respond_to?(:current_user)
              current_user
            end
          end
        end

        operation.new(params: params, request: request, scope: scope)
      end
    end
  end
end
