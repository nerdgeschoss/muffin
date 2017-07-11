module Muffin
  module Rails
    module ControllerAdditions
      def prepare(operation, options = {})
        options["scope"] = current_user if !options[:user] && !options["user"] && respond_to?(:current_user)


        if !options[:params] && !options["params"] && respond_to?(:params) && operation.respond_to?(:model_name)
          if params.has_key?(operation.model_name.underscore)
            options["params"] = params[operation.model_name.underscore].deep_dup.permit!.to_h
            options["params"].deep_transform_keys! do |key|
              if key.to_s[/.+_attributes\Z/]
                new_key = key.to_s.sub(/_attributes\Z/, "")
                key.is_a?(Symbol) ? new_key.to_sym : new_key
              else
                key
              end
            end
          end
        end

        options["request"] = request if !options[:request] && !options["request"] && respond_to?(:request)
        options["scope"] = current_user if !options[:user] && !options["user"] && respond_to?(:current_user)

        operation.new(options)
      end
    end
  end
end
