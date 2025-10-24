# frozen_string_literal: true

module Ruby
  module Effect
    # Duration for time handling
    class Duration
      attr_reader :nanos

      def initialize(nanos)
        @nanos = nanos
      end

      # Creates a duration from milliseconds
      # @param n [Integer] Milliseconds
      # @return [Duration] Duration
      def self.millis(n)
        new(n * 1_000_000)
      end

      # Creates a duration from seconds
      # @param n [Integer] Seconds
      # @return [Duration] Duration
      def self.seconds(n)
        new(n * 1_000_000_000)
      end

      # Creates a duration from minutes
      # @param n [Integer] Minutes
      # @return [Duration] Duration
      def self.minutes(n)
        new(n * 60 * 1_000_000_000)
      end

      # Creates a duration from hours
      # @param n [Integer] Hours
      # @return [Duration] Duration
      def self.hours(n)
        new(n * 60 * 60 * 1_000_000_000)
      end

      # Converts to milliseconds
      # @return [Integer] Milliseconds
      def to_millis
        @nanos / 1_000_000
      end

      # Converts to seconds
      # @return [Float] Seconds
      def to_seconds
        @nanos / 1_000_000_000.0
      end

      # Adds two durations
      # @param other [Duration] Other duration
      # @return [Duration] Sum duration
      def +(other)
        Duration.new(@nanos + other.nanos)
      end

      # Subtracts two durations
      # @param other [Duration] Other duration
      # @return [Duration] Difference duration
      def -(other)
        Duration.new(@nanos - other.nanos)
      end

      # Multiplies duration by a scalar
      # @param scalar [Numeric] Scalar value
      # @return [Duration] Scaled duration
      def *(scalar)
        Duration.new(@nanos * scalar)
      end

      # Compares two durations
      # @param other [Duration] Other duration
      # @return [Integer] -1, 0, or 1
      def <=>(other)
        @nanos <=> other.nanos
      end

      include Comparable

      def to_s
        if @nanos < 1_000_000
          "#{@nanos}ns"
        elsif @nanos < 1_000_000_000
          "#{to_millis}ms"
        else
          "#{to_seconds}s"
        end
      end

      def ==(other)
        other.is_a?(Duration) && @nanos == other.nanos
      end
    end
  end
end

