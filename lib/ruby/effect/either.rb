# frozen_string_literal: true

module Ruby
  module Effect
    # Either type for error handling
    class Either
      attr_reader :value

      def initialize(value, is_right)
        @value = value
        @is_right = is_right
      end

      # Creates a Left either
      # @param value [Object] The left value
      # @return [Either] Left either
      def self.left(value)
        new(value, false)
      end

      # Creates a Right either
      # @param value [Object] The right value
      # @return [Either] Right either
      def self.right(value)
        new(value, true)
      end

      # Checks if this is Right
      # @return [Boolean] True if Right
      def right?
        @is_right
      end

      # Checks if this is Left
      # @return [Boolean] True if Left
      def left?
        !@is_right
      end

      # Maps the right value
      # @param block [Proc] Transformation function
      # @return [Either] New either
      def map(&block)
        @is_right ? Either.right(block.call(@value)) : self
      end

      # Maps the left value
      # @param block [Proc] Transformation function
      # @return [Either] New either
      def map_left(&block)
        @is_right ? self : Either.left(block.call(@value))
      end

      # Flat maps the right value
      # @param block [Proc] Function returning an Either
      # @return [Either] New either
      def flat_map(&block)
        @is_right ? block.call(@value) : self
      end

      # Swaps left and right
      # @return [Either] Swapped either
      def swap
        @is_right ? Either.left(@value) : Either.right(@value)
      end

      # Gets the right value or a default
      # @param default [Object] Default value
      # @return [Object] The value or default
      def get_or_else(default)
        @is_right ? @value : default
      end

      # Matches on this either
      # @param on_left [Proc] Left handler
      # @param on_right [Proc] Right handler
      # @return [Object] Result of handler
      def match(on_left:, on_right:)
        @is_right ? on_right.call(@value) : on_left.call(@value)
      end

      def to_s
        @is_right ? "Right(#{@value.inspect})" : "Left(#{@value.inspect})"
      end

      def ==(other)
        other.is_a?(Either) && @is_right == other.right? && @value == other.value
      end
    end
  end
end

