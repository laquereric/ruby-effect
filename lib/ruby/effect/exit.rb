# frozen_string_literal: true

module Ruby
  module Effect
    # Exit represents the result of an effect execution
    class Exit
      attr_reader :value, :cause

      def initialize(value: nil, cause: nil)
        @value = value
        @cause = cause
      end

      # Creates a successful exit
      # @param value [Object] Success value
      # @return [Exit] Success exit
      def self.success(value)
        new(value: value)
      end

      # Creates a failed exit
      # @param cause [Cause] Failure cause
      # @return [Exit] Failure exit
      def self.failure(cause)
        new(cause: cause)
      end

      # Checks if this exit is successful
      # @return [Boolean] True if successful
      def success?
        @cause.nil?
      end

      # Checks if this exit is a failure
      # @return [Boolean] True if failed
      def failure?
        !success?
      end

      # Matches on this exit
      # @param on_success [Proc] Success handler
      # @param on_failure [Proc] Failure handler
      # @return [Object] Result of the handler
      def match(on_success:, on_failure:)
        if success?
          on_success.call(@value)
        else
          on_failure.call(@cause)
        end
      end

      # Maps the success value
      # @param block [Proc] Transformation function
      # @return [Exit] New exit
      def map(&block)
        if success?
          Exit.success(block.call(@value))
        else
          self
        end
      end

      # Flat maps the success value
      # @param block [Proc] Function returning an Exit
      # @return [Exit] New exit
      def flat_map(&block)
        if success?
          block.call(@value)
        else
          self
        end
      end

      def to_s
        if success?
          "Exit.Success(#{@value.inspect})"
        else
          "Exit.Failure(#{@cause})"
        end
      end
    end
  end
end

