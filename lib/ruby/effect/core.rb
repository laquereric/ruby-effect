# frozen_string_literal: true

module Ruby
  module Effect
    # Core Effect class representing a lazy computation
    # Effect<Success, Error, Requirements>
    class Core
      attr_reader :thunk, :context_requirements, :is_async

      def initialize(thunk:, context_requirements: [], is_async: false)
        @thunk = thunk
        @context_requirements = context_requirements
        @is_async = is_async
      end

      # Maps the success value of this effect
      # @param block [Proc] Transformation function
      # @return [Core] New effect with transformed value
      def map(&block)
        Core.new(
          thunk: -> {
            exit = run_internal(Context.empty)
            if exit.success?
              Exit.success(block.call(exit.value))
            else
              exit
            end
          },
          context_requirements: @context_requirements,
          is_async: @is_async
        )
      end

      # Flat maps this effect with another effect
      # @param block [Proc] Function that returns an Effect
      # @return [Core] New effect
      def flat_map(&block)
        Core.new(
          thunk: -> {
            exit = run_internal(Context.empty)
            if exit.success?
              next_effect = block.call(exit.value)
              next_effect.run_internal(Context.empty)
            else
              exit
            end
          },
          context_requirements: @context_requirements,
          is_async: @is_async
        )
      end

      alias_method :and_then, :flat_map
      alias_method :bind, :flat_map

      # Catches all errors and recovers
      # @param block [Proc] Recovery function
      # @return [Core] New effect
      def catch_all(&block)
        Core.new(
          thunk: -> {
            exit = run_internal(Context.empty)
            if exit.failure?
              recovery_effect = block.call(exit.cause.failures.first)
              recovery_effect.run_internal(Context.empty)
            else
              exit
            end
          },
          context_requirements: @context_requirements,
          is_async: @is_async
        )
      end

      # Catches errors with a specific tag
      # @param tag [Symbol] Error tag to match
      # @param block [Proc] Recovery function
      # @return [Core] New effect
      def catch_tag(tag, &block)
        catch_all do |error|
          if error.respond_to?(:_tag) && error._tag == tag
            block.call(error)
          else
            Ruby::Effect.fail(error)
          end
        end
      end

      # Provides context to this effect
      # @param context [Context] The context to provide
      # @return [Core] New effect with context
      def provide(context)
        Core.new(
          thunk: -> { run_internal(context) },
          context_requirements: [],
          is_async: @is_async
        )
      end

      # Retries this effect with a schedule
      # @param schedule [Schedule] Retry schedule
      # @return [Core] New effect with retry logic
      def retry(schedule)
        Core.new(
          thunk: -> {
            attempts = 0
            loop do
              exit = run_internal(Context.empty)
              return exit if exit.success?
              
              attempts += 1
              break exit unless schedule.should_retry?(attempts)
              
              sleep(schedule.delay(attempts))
            end
          },
          context_requirements: @context_requirements,
          is_async: @is_async
        )
      end

      # Adds a timeout to this effect
      # @param duration [Duration] Timeout duration
      # @return [Core] New effect with timeout
      def timeout(duration)
        Core.new(
          thunk: -> {
            require 'timeout'
            begin
              Timeout.timeout(duration.to_seconds) do
                run_internal(Context.empty)
              end
            rescue Timeout::Error
              Exit.failure(Cause.fail(TimeoutError.new("Effect timed out after #{duration}")))
            end
          },
          context_requirements: @context_requirements,
          is_async: @is_async
        )
      end

      # Forks this effect into a fiber
      # @return [Core] Effect that produces a Fiber
      def fork
        Core.new(
          thunk: -> {
            fiber = Fiber.fork(self)
            Exit.success(fiber)
          },
          context_requirements: @context_requirements,
          is_async: true
        )
      end

      # Runs this effect synchronously
      # @return [Object] The success value
      # @raise [Error] If the effect fails
      def run_sync
        exit = run_internal(Context.empty)
        if exit.success?
          exit.value
        else
          raise Error, "Effect failed: #{exit.cause}"
        end
      end

      # Runs this effect and returns a promise-like object
      # @return [Exit] The exit result
      def run_promise
        if @is_async
          Thread.new { run_internal(Context.empty) }
        else
          run_internal(Context.empty)
        end
      end

      # Internal execution method
      # @param context [Context] The execution context
      # @return [Exit] The exit result
      def run_internal(context)
        @thunk.call
      end

      # Matches on the result of this effect
      # @param on_success [Proc] Success handler
      # @param on_failure [Proc] Failure handler
      # @return [Core] New effect
      def match(on_success:, on_failure:)
        Core.new(
          thunk: -> {
            exit = run_internal(Context.empty)
            if exit.success?
              Exit.success(on_success.call(exit.value))
            else
              Exit.success(on_failure.call(exit.cause))
            end
          },
          context_requirements: @context_requirements,
          is_async: @is_async
        )
      end

      # Taps into the success value without changing it
      # @param block [Proc] Side effect function
      # @return [Core] This effect
      def tap(&block)
        map do |value|
          block.call(value)
          value
        end
      end

      # Combines two effects sequentially
      # @param other [Core] The other effect
      # @return [Core] New effect
      def zip(other)
        flat_map { |a| other.map { |b| [a, b] } }
      end

      # Runs this effect, ignoring the result
      # @return [Core] New effect that produces nil
      def ignore
        map { nil }
      end
    end

    class TimeoutError < StandardError; end
  end
end

