require "bundler/setup"
require "muffin"

if RUBY_ENGINE == "ruby"
  if ENV["CI"]
    # CI stuff
  else
    begin
      require "pry"
    rescue LoadError
    end

    begin
      require "simplecov"
      SimpleCov.start
    rescue LoadError
    end
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.default_formatter = "doc" if config.files_to_run.one?
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end
