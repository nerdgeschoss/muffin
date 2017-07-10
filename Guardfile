guard :rspec, cmd: "bundle exec rspec" do
  require "guard/rspec/dsl"
  dsl = Guard::RSpec::Dsl.new(self)

  # RSpec files
  rspec = dsl.rspec
  watch(rspec.spec_files)

  watch(%r{^lib/muffin/(.+)\.rb$}) { |m| "spec/models/#{m[1]}_spec.rb" }
end
