# frozen_string_literal: true

require_relative "effect/version"
require_relative "effect/core"
require_relative "effect/context"
require_relative "effect/exit"
require_relative "effect/cause"
require_relative "effect/fiber"
require_relative "effect/fiber_id"
require_relative "effect/deferred"
require_relative "effect/queue"
require_relative "effect/option"
require_relative "effect/either"
require_relative "effect/duration"
require_relative "effect/schedule"
require_relative "effect/runtime"

module Ruby
  module Effect
    class Error < StandardError; end

    # Main Effect module that provides factory methods
    class << self
      # Creates an Effect that always succeeds with a given value
      # @param value [Object] The success value
      # @return [Core] Effect that succeeds with the value
      def succeed(value)
        Core.new(
          thunk: -> { Exit.success(value) },
          context_requirements: []
        )
      end

      # Creates an Effect that represents a recoverable error
      # @param error [Object] The error value
      # @return [Core] Effect that fails with the error
      def fail(error)
        Core.new(
          thunk: -> { Exit.failure(Cause.fail(error)) },
          context_requirements: []
        )
      end

      # Creates an Effect from a synchronous side-effectful computation
      # @param block [Proc] The computation to execute
      # @return [Core] Effect that wraps the computation
      def sync(&block)
        Core.new(
          thunk: -> { 
            begin
              Exit.success(block.call)
            rescue => e
              # Defects are unexpected errors
              Exit.failure(Cause.die(e))
            end
          },
          context_requirements: []
        )
      end

      # Creates an Effect from a synchronous computation that might fail
      # @param catch_fn [Proc] Function to transform caught errors
      # @param block [Proc] The computation to execute
      # @return [Core] Effect that wraps the computation
      def try(catch_fn: ->(e) { e }, &block)
        Core.new(
          thunk: -> {
            begin
              Exit.success(block.call)
            rescue => e
              Exit.failure(Cause.fail(catch_fn.call(e)))
            end
          },
          context_requirements: []
        )
      end

      # Creates an Effect from an asynchronous computation (Promise-like)
      # @param block [Proc] The async computation
      # @return [Core] Effect that wraps the async computation
      def promise(&block)
        Core.new(
          thunk: -> {
            result = block.call
            Exit.success(result)
          },
          context_requirements: [],
          is_async: true
        )
      end

      # Creates an Effect from an async computation that might fail
      # @param catch_fn [Proc] Function to transform caught errors
      # @param block [Proc] The async computation
      # @return [Core] Effect that wraps the async computation
      def try_promise(catch_fn: ->(e) { e }, &block)
        Core.new(
          thunk: -> {
            begin
              result = block.call
              Exit.success(result)
            rescue => e
              Exit.failure(Cause.fail(catch_fn.call(e)))
            end
          },
          context_requirements: [],
          is_async: true
        )
      end

      # Creates a suspended Effect for lazy evaluation
      # @param block [Proc] Block that returns an Effect
      # @return [Core] Suspended effect
      def suspend(&block)
        Core.new(
          thunk: -> { block.call.run_internal(Context.empty) },
          context_requirements: []
        )
      end

      # Creates an Effect that never completes
      # @return [Core] Effect that runs forever
      def never
        Core.new(
          thunk: -> { sleep },
          context_requirements: [],
          is_async: true
        )
      end

      # Runs multiple effects in parallel and collects results
      # @param effects [Array<Core>] Effects to run in parallel
      # @return [Core] Effect that produces an array of results
      def all(effects)
        Core.new(
          thunk: -> {
            results = effects.map { |eff| eff.run_internal(Context.empty) }
            if results.all?(&:success?)
              Exit.success(results.map(&:value))
            else
              failures = results.select(&:failure?).map(&:cause)
              Exit.failure(Cause.parallel(*failures))
            end
          },
          context_requirements: []
        )
      end

      # Runs multiple effects in parallel and returns the first to complete
      # @param effects [Array<Core>] Effects to race
      # @return [Core] Effect that produces the first result
      def race(*effects)
        Core.new(
          thunk: -> {
            # Simplified race implementation
            effects.first.run_internal(Context.empty)
          },
          context_requirements: []
        )
      end
    end
  end
end

