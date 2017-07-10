require_relative "frostings/attributes"
require_relative "frostings/validation"
require_relative "frostings/execution"
require_relative "frostings/policy"

module Muffin
  class Base
    include Attributes
    include Validation
    include Execution
    include Policy

    attr_reader :request, :params, :scope

    def initialize(request: nil, params: nil, scope: nil)
      @request = request
      @params = params || {}
      @scope = scope

      assign_attributes
    end
  end
end
