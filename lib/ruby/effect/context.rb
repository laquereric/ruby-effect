# frozen_string_literal: true

module Ruby
  module Effect
    # Context for dependency injection
    class Context
      attr_reader :services

      def initialize(services = {})
        @services = services.dup.freeze
      end

      # Creates an empty context
      # @return [Context] Empty context
      def self.empty
        new({})
      end

      # Adds a service to the context
      # @param tag [Symbol] Service tag/identifier
      # @param service [Object] Service implementation
      # @return [Context] New context with the service
      def add(tag, service)
        Context.new(@services.merge(tag => service))
      end

      # Gets a service from the context
      # @param tag [Symbol] Service tag/identifier
      # @return [Object] The service
      # @raise [Error] If service not found
      def get(tag)
        @services.fetch(tag) do
          raise Error, "Service not found: #{tag}"
        end
      end

      # Checks if a service exists
      # @param tag [Symbol] Service tag/identifier
      # @return [Boolean] True if service exists
      def has?(tag)
        @services.key?(tag)
      end

      # Merges this context with another
      # @param other [Context] The other context
      # @return [Context] New merged context
      def merge(other)
        Context.new(@services.merge(other.services))
      end

      # Returns the number of services
      # @return [Integer] Number of services
      def size
        @services.size
      end

      # Checks if context is empty
      # @return [Boolean] True if empty
      def empty?
        @services.empty?
      end
    end

    # Service tag for dependency injection
    class Service
      attr_reader :tag

      def initialize(tag)
        @tag = tag
      end

      # Creates a service tag
      # @param tag [Symbol] Service identifier
      # @return [Service] Service tag
      def self.of(tag)
        new(tag)
      end

      # Creates a layer that provides this service
      # @param implementation [Object] Service implementation
      # @return [Layer] Layer that provides the service
      def provide(implementation)
        Layer.new(
          build: Ruby::Effect.succeed(Context.empty.add(@tag, implementation))
        )
      end
    end

    # Layer for building service dependencies
    class Layer
      attr_reader :build

      def initialize(build:)
        @build = build
      end

      # Provides this layer to an effect
      # @param effect [Core] The effect to provide to
      # @return [Core] New effect with layer provided
      def provide_to(effect)
        @build.flat_map do |context|
          effect.provide(context)
        end
      end

      # Combines this layer with another sequentially
      # @param other [Layer] The other layer
      # @return [Layer] Combined layer
      def and_then(other)
        Layer.new(
          build: @build.flat_map do |ctx1|
            other.build.map do |ctx2|
              ctx1.merge(ctx2)
            end
          end
        )
      end

      alias_method :>>, :and_then

      # Memoizes this layer
      # @return [Core] Effect that produces a memoized layer
      def memoize
        memo = nil
        Layer.new(
          build: Ruby::Effect.sync do
            memo ||= @build.run_sync
            memo
          end
        )
      end
    end
  end
end

