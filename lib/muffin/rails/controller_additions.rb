module Muffin
  module Rails
    SCOPE_ACCESSOR = :operation_auth_scope

    module ControllerAdditions
      def prepare(operation, params: nil, request: nil, scope: nil, **additional_params)
        if params.blank? && respond_to?(:params) && operation.respond_to?(:model_name)
          if self.params.key?(operation.model_name.param_key) || operation.model_name.param_key.blank?
            params = (operation.model_name.param_key.blank? ? self.params : self.params[operation.model_name.param_key]).deep_dup.permit!.to_h
            params.deep_transform_keys! do |key|
              if key.to_s[/.+_attributes\Z/]
                new_key = key.to_s.sub(/_attributes\Z/, "")
                key.is_a?(Symbol) ? new_key.to_sym : new_key
              else
                key
              end
            end

            params = params.transform_values do |value|
              if value.try(:keys).try(:map, &:to_s).try(:all?) { |e| e[/\A\d+\Z/] }
                value.values
              else
                value
              end
            end
          end
        end

        params = (params || {}).merge(additional_params) if additional_params.present?
        request ||= try(:request)

        # we need this clumsy construct because the scope accessor/current_user can be a private method
        scope ||= if respond_to?(Muffin::Rails::SCOPE_ACCESSOR, true)
          send(Muffin::Rails::SCOPE_ACCESSOR)
        elsif respond_to?(:current_user, true)
          send(:current_user)
        end

        operation.new(params: params, request: request, scope: scope)
      end
    end
  end
end
