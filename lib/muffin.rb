require "active_support"
require "active_support/core_ext"
require "muffin/version"

module Muffin
  require_relative "./muffin/base"
  require_relative "./muffin/rails/controller_additions"
end
