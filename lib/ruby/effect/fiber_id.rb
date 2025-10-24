# frozen_string_literal: true

module Ruby
  module Effect
    # FiberId for fiber identification
    class FiberId
      attr_reader :id, :start_time

      @@counter = 0
      @@mutex = Mutex.new

      def initialize(id, start_time)
        @id = id
        @start_time = start_time
      end

      # Creates a new fiber ID
      # @return [FiberId] New fiber ID
      def self.make
        id = @@mutex.synchronize do
          @@counter += 1
          @@counter
        end
        new(id, Time.now)
      end

      def to_s
        "#FiberId<#{@id}>"
      end

      def ==(other)
        other.is_a?(FiberId) && @id == other.id
      end

      def hash
        @id.hash
      end

      alias_method :eql?, :==
    end
  end
end

