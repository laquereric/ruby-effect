# frozen_string_literal: true

require 'thread'

module Ruby
  module Effect
    # Queue for concurrent data structures
    class Queue
      attr_reader :capacity

      def initialize(capacity = nil)
        @capacity = capacity
        @queue = ::Queue.new
      end

      # Creates a bounded queue
      # @param capacity [Integer] Maximum capacity
      # @return [Core] Effect that produces a Queue
      def self.bounded(capacity)
        Ruby::Effect.sync { new(capacity) }
      end

      # Creates an unbounded queue
      # @return [Core] Effect that produces a Queue
      def self.unbounded
        Ruby::Effect.sync { new }
      end

      # Offers an item to the queue
      # @param item [Object] Item to offer
      # @return [Core] Effect that produces true if accepted
      def offer(item)
        Ruby::Effect.sync do
          if @capacity && @queue.size >= @capacity
            false
          else
            @queue.push(item)
            true
          end
        end
      end

      # Takes an item from the queue (blocking)
      # @return [Core] Effect that produces the item
      def take
        Ruby::Effect.sync { @queue.pop }
      end

      # Returns the current size of the queue
      # @return [Core] Effect that produces the size
      def size
        Ruby::Effect.sync { @queue.size }
      end

      # Checks if the queue is empty
      # @return [Core] Effect that produces true if empty
      def empty?
        Ruby::Effect.sync { @queue.empty? }
      end

      # Checks if the queue is full
      # @return [Core] Effect that produces true if full
      def full?
        Ruby::Effect.sync do
          @capacity && @queue.size >= @capacity
        end
      end
    end
  end
end

