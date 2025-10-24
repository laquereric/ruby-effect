# frozen_string_literal: true

module Ruby
  module Effect
    # Runtime for executing effects
    class Runtime
      attr_reader :context

      def initialize(context: Context.empty)
        @context = context
      end

      # Creates a default runtime
      # @return [Runtime] Default runtime
      def self.default
        new
      end

      # Runs an effect synchronously
      # @param effect [Core] Effect to run
      # @return [Object] The success value
      # @raise [Error] If the effect fails
      def run_sync(effect)
        effect.provide(@context).run_sync
      end

      # Runs an effect and returns a promise-like object
      # @param effect [Core] Effect to run
      # @return [Thread] Thread executing the effect
      def run_promise(effect)
        effect.provide(@context).run_promise
      end

      # Forks an effect into a fiber
      # @param effect [Core] Effect to fork
      # @return [Fiber] The fiber
      def run_fork(effect)
        fiber = Fiber.fork(effect.provide(@context))
        fiber
      end

      # Creates a new runtime with additional context
      # @param context [Context] Additional context
      # @return [Runtime] New runtime
      def with_context(context)
        Runtime.new(context: @context.merge(context))
      end
    end
  end
end

