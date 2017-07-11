source "https://rubygems.org"

# Specify your gem's dependencies in muffin.gemspec
gemspec

group :development, :test do
  gem "activesupport"
  gem "bundler"
  gem "guard-rspec"
  gem "rails"
  gem "rake"
  gem "rspec", "~> 3.0"
  gem "rubocop"
  gem "rubocop-rspec-focused"

  if RUBY_ENGINE == "ruby"
    gem "simplecov" if RUBY_VERSION >= "2.0.0"

    unless ENV["CI"]
      gem "pry"

      if RUBY_VERSION < "2.0.0"
        gem "pry-nav"
      else
        gem "pry-byebug"
      end

      # yard and friends
      gem "github-markup"
      gem "redcarpet"
      gem "yard"
    end
  end
end
