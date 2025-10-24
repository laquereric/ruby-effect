# frozen_string_literal: true

module Ruby
  module Effect
    # Schedule for retrying and repetition
    class Schedule
      attr_reader :should_retry_fn, :delay_fn

      def initialize(should_retry_fn:, delay_fn:)
        @should_retry_fn = should_retry_fn
        @delay_fn = delay_fn
      end

      # Creates a schedule that retries forever
      # @return [Schedule] Forever schedule
      def self.forever
        new(
          should_retry_fn: ->(_) { true },
          delay_fn: ->(_) { 0 }
        )
      end

      # Creates a schedule that retries once
      # @return [Schedule] Once schedule
      def self.once
        new(
          should_retry_fn: ->(n) { n <= 1 },
          delay_fn: ->(_) { 0 }
        )
      end

      # Creates a schedule that retries n times
      # @param n [Integer] Number of retries
      # @return [Schedule] Recurs schedule
      def self.recurs(n)
        new(
          should_retry_fn: ->(attempts) { attempts <= n },
          delay_fn: ->(_) { 0 }
        )
      end

      # Creates a schedule with fixed spacing
      # @param duration [Duration] Delay duration
      # @return [Schedule] Spaced schedule
      def self.spaced(duration)
        new(
          should_retry_fn: ->(_) { true },
          delay_fn: ->(_) { duration.to_seconds }
        )
      end

      # Creates a schedule with exponential backoff
      # @param base [Duration] Base duration
      # @param factor [Numeric] Multiplication factor
      # @return [Schedule] Exponential schedule
      def self.exponential(base, factor = 2.0)
        new(
          should_retry_fn: ->(_) { true },
          delay_fn: ->(n) { base.to_seconds * (factor ** (n - 1)) }
        )
      end

      # Creates a schedule with fibonacci backoff
      # @param base [Duration] Base duration
      # @return [Schedule] Fibonacci schedule
      def self.fibonacci(base)
        new(
          should_retry_fn: ->(_) { true },
          delay_fn: ->(n) {
            fib = n <= 2 ? 1 : fibonacci_number(n)
            base.to_seconds * fib
          }
        )
      end

      # Checks if should retry
      # @param attempts [Integer] Number of attempts
      # @return [Boolean] True if should retry
      def should_retry?(attempts)
        @should_retry_fn.call(attempts)
      end

      # Gets the delay for an attempt
      # @param attempts [Integer] Number of attempts
      # @return [Numeric] Delay in seconds
      def delay(attempts)
        @delay_fn.call(attempts)
      end

      # Composes this schedule with another
      # @param other [Schedule] Other schedule
      # @return [Schedule] Composed schedule
      def compose(other)
        Schedule.new(
          should_retry_fn: ->(n) { @should_retry_fn.call(n) && other.should_retry?(n) },
          delay_fn: ->(n) { [@delay_fn.call(n), other.delay(n)].max }
        )
      end

      # alias_method :&&, :compose # Cannot alias && operator

      private

      def self.fibonacci_number(n)
        return 1 if n <= 2
        a, b = 1, 1
        (n - 2).times do
          a, b = b, a + b
        end
        b
      end
    end
  end
end

