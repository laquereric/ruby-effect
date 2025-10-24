# frozen_string_literal: true

module Ruby
  module Effect
    # Deferred for fiber communication
    class Deferred
      def initialize
        @mutex = Mutex.new
        @condition = ConditionVariable.new
        @value = nil
        @completed = false
      end

      # Creates a new Deferred
      # @return [Core] Effect that produces a Deferred
      def self.make
        Ruby::Effect.sync { new }
      end

      # Completes this deferred with a success value
      # @param value [Object] Success value
      # @return [Core] Effect that produces true if completed
      def succeed(value)
        Ruby::Effect.sync do
          @mutex.synchronize do
            unless @completed
              @value = Exit.success(value)
              @completed = true
              @condition.broadcast
              true
            else
              false
            end
          end
        end
      end

      # Completes this deferred with a failure
      # @param error [Object] Error value
      # @return [Core] Effect that produces true if completed
      def fail(error)
        Ruby::Effect.sync do
          @mutex.synchronize do
            unless @completed
              @value = Exit.failure(Cause.fail(error))
              @completed = true
              @condition.broadcast
              true
            else
              false
            end
          end
        end
      end

      # Awaits the completion of this deferred
      # @return [Core] Effect that produces the value
      def await
        Ruby::Effect.sync do
          @mutex.synchronize do
            @condition.wait(@mutex) unless @completed
            if @value.success?
              @value.value
            else
              raise Error, "Deferred failed: #{@value.cause}"
            end
          end
        end
      end

      # Polls this deferred without blocking
      # @return [Core] Effect that produces an Option<Exit>
      def poll
        Ruby::Effect.sync do
          @mutex.synchronize do
            if @completed
              Option.some(@value)
            else
              Option.none
            end
          end
        end
      end
    end
  end
end

