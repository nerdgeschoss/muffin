require_relative "frostings/attributes"
require_relative "frostings/validation"
require_relative "frostings/execution"
require_relative "frostings/policy"
require_relative "frostings/sync"

module Muffin
  class Base
    extend ActiveModel::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::Naming
    include Attributes
    include Validation
    include Execution
    include Policy
    include Sync

    attr_reader :request, :params, :scope

    define_model_callbacks :initialize

    validates_with Muffin::Validation::NestedAttributesValidator

    def initialize(request: nil, params: nil, scope: nil)
      run_callbacks :initialize do
        @request = request
        @params = params || {}
        @scope = scope

        assign_attributes
        true # after callbacks seem not to be invoked if the result is falsy
      end
    end
  end
end
