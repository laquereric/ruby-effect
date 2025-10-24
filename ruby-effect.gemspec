# frozen_string_literal: true

require_relative "lib/ruby/effect/version"

Gem::Specification.new do |spec|
  spec.name = "ruby-effect"
  spec.version = Ruby::Effect::VERSION
  spec.authors = ["Ruby Effect Team"]
  spec.email = ["ruby-effect@example.com"]

  spec.summary = "A Ruby implementation of Effect-TS functional effect system"
  spec.description = "Ruby-Effect provides a powerful functional effect system inspired by Effect-TS, enabling developers to build robust, composable, and type-safe applications with explicit error handling, dependency injection, and concurrency support."
  spec.homepage = "https://github.com/ruby-effect/ruby-effect"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ruby-effect/ruby-effect"
  spec.metadata["changelog_uri"] = "https://github.com/ruby-effect/ruby-effect/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end

