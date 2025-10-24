# frozen_string_literal: true

module Ruby
  module Effect
    # Option type for optional values
    class Option
      attr_reader :value

      def initialize(value, is_some)
        @value = value
        @is_some = is_some
      end

      # Creates a Some option
      # @param value [Object] The value
      # @return [Option] Some option
      def self.some(value)
        new(value, true)
      end

      # Creates a None option
      # @return [Option] None option
      def self.none
        new(nil, false)
      end

      # Checks if this is Some
      # @return [Boolean] True if Some
      def some?
        @is_some
      end

      # Checks if this is None
      # @return [Boolean] True if None
      def none?
        !@is_some
      end

      # Gets the value or returns a default
      # @param default [Object] Default value
      # @return [Object] The value or default
      def get_or_else(default)
        @is_some ? @value : default
      end

      # Maps the value if Some
      # @param block [Proc] Transformation function
      # @return [Option] New option
      def map(&block)
        @is_some ? Option.some(block.call(@value)) : self
      end

      # Flat maps the value if Some
      # @param block [Proc] Function returning an Option
      # @return [Option] New option
      def flat_map(&block)
        @is_some ? block.call(@value) : self
      end

      # Filters the value
      # @param block [Proc] Predicate function
      # @return [Option] Filtered option
      def filter(&block)
        @is_some && block.call(@value) ? self : Option.none
      end

      # Matches on this option
      # @param on_some [Proc] Some handler
      # @param on_none [Proc] None handler
      # @return [Object] Result of handler
      def match(on_some:, on_none:)
        @is_some ? on_some.call(@value) : on_none.call
      end

      def to_s
        @is_some ? "Some(#{@value.inspect})" : "None"
      end

      def ==(other)
        other.is_a?(Option) && @is_some == other.some? && @value == other.value
      end
    end
  end
end

