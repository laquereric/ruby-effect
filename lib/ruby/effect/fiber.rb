# frozen_string_literal: true

module Ruby
  module Effect
    # Fiber for lightweight concurrency
    class Fiber
      attr_reader :fiber_id, :thread

      def initialize(effect)
        @fiber_id = FiberId.make
        @effect = effect
        @thread = nil
        @result = nil
        @mutex = Mutex.new
        @condition = ConditionVariable.new
      end

      # Forks an effect into a fiber
      # @param effect [Core] Effect to fork
      # @return [Fiber] The fiber
      def self.fork(effect)
        fiber = new(effect)
        fiber.start
        fiber
      end

      # Starts this fiber
      def start
        @thread = Thread.new do
          @result = @effect.run_internal(Context.empty)
          @mutex.synchronize { @condition.broadcast }
        end
      end

      # Joins this fiber, waiting for completion
      # @return [Core] Effect that produces the result
      def join
        Ruby::Effect.sync do
          @thread.join if @thread
          if @result.success?
            @result.value
          else
            raise Error, "Fiber failed: #{@result.cause}"
          end
        end
      end

      # Awaits this fiber, returning an Exit
      # @return [Core] Effect that produces an Exit
      def await
        Ruby::Effect.sync do
          @thread.join if @thread
          @result
        end
      end

      # Interrupts this fiber
      # @return [Core] Effect that produces an Exit
      def interrupt
        Ruby::Effect.sync do
          @thread.kill if @thread&.alive?
          Exit.failure(Cause.interrupt(@fiber_id))
        end
      end

      # Checks if this fiber is running
      # @return [Boolean] True if running
      def running?
        @thread&.alive? || false
      end

      # Checks if this fiber is done
      # @return [Boolean] True if done
      def done?
        !running?
      end
    end
  end
end

