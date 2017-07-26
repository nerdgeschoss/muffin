require_relative "frostings/attributes"
require_relative "frostings/validation"
require_relative "frostings/execution"
require_relative "frostings/policy"
require_relative "frostings/sync"

module Muffin
  class Base
    include ActiveModel::Conversion
    include ActiveModel::Naming
    include Attributes
    include Validation
    include Execution
    include Policy
    include Sync

    attr_reader :request, :params, :scope

    validates_with Muffin::Validation::NestedAttributesValidator

    def initialize(request: nil, params: nil, scope: nil)
      @request = request
      @params = params || {}
      @scope = scope

      assign_attributes
    end
  end
end
