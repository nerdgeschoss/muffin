lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "muffin/version"

Gem::Specification.new do |spec|
  spec.name          = "muffin"
  spec.version       = Muffin::VERSION
  spec.authors       = ["Jens Ravens", "Michael Sievers"]
  spec.email         = ["jens@nerdgeschoss.de", "michael@nerdgeschoss.de"]

  spec.summary       = "Simple operations with optional icing on top."
  spec.homepage      = "https://github.com/nerdgeschoss/muffin"
  spec.license       = "MIT"

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "activemodel"
end
