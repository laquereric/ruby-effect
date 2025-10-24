# frozen_string_literal: true

module Ruby
  module Effect
    # Cause represents the cause of effect failure
    class Cause
      attr_reader :type, :error, :left, :right

      def initialize(type:, error: nil, left: nil, right: nil)
        @type = type
        @error = error
        @left = left
        @right = right
      end

      # Creates a failure cause
      # @param error [Object] The error
      # @return [Cause] Failure cause
      def self.fail(error)
        new(type: :fail, error: error)
      end

      # Creates a defect cause (unexpected error)
      # @param defect [Exception] The defect
      # @return [Cause] Defect cause
      def self.die(defect)
        new(type: :die, error: defect)
      end

      # Creates an interrupt cause
      # @param fiber_id [FiberId] The fiber ID
      # @return [Cause] Interrupt cause
      def self.interrupt(fiber_id)
        new(type: :interrupt, error: fiber_id)
      end

      # Creates a sequential composition of causes
      # @param left [Cause] Left cause
      # @param right [Cause] Right cause
      # @return [Cause] Sequential cause
      def self.sequential(left, right)
        new(type: :sequential, left: left, right: right)
      end

      # Creates a parallel composition of causes
      # @param causes [Array<Cause>] Causes to combine
      # @return [Cause] Parallel cause
      def self.parallel(*causes)
        return causes.first if causes.size == 1
        causes.reduce { |acc, cause| new(type: :parallel, left: acc, right: cause) }
      end

      # Collects all failures from this cause
      # @return [Array<Object>] All failures
      def failures
        case @type
        when :fail
          [@error]
        when :sequential, :parallel
          @left.failures + @right.failures
        else
          []
        end
      end

      # Collects all defects from this cause
      # @return [Array<Exception>] All defects
      def defects
        case @type
        when :die
          [@error]
        when :sequential, :parallel
          @left.defects + @right.defects
        else
          []
        end
      end

      # Checks if this cause is a failure
      # @return [Boolean] True if failure
      def failure?
        @type == :fail
      end

      # Checks if this cause is a defect
      # @return [Boolean] True if defect
      def defect?
        @type == :die
      end

      # Checks if this cause is an interrupt
      # @return [Boolean] True if interrupt
      def interrupt?
        @type == :interrupt
      end

      def to_s
        case @type
        when :fail
          "Fail(#{@error.inspect})"
        when :die
          "Die(#{@error.class}: #{@error.message})"
        when :interrupt
          "Interrupt(#{@error})"
        when :sequential
          "Sequential(#{@left}, #{@right})"
        when :parallel
          "Parallel(#{@left}, #{@right})"
        end
      end
    end
  end
end

