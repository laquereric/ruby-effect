# frozen_string_literal: true

RSpec.describe Ruby::Effect do
  it "has a version number" do
    expect(Ruby::Effect::VERSION).not_to be nil
  end

  describe ".succeed" do
    it "creates a successful effect" do
      effect = Ruby::Effect.succeed(42)
      result = effect.run_sync
      expect(result).to eq(42)
    end
  end

  describe ".fail" do
    it "creates a failed effect" do
      effect = Ruby::Effect.fail("error")
      expect { effect.run_sync }.to raise_error(Ruby::Effect::Error)
    end
  end

  describe ".sync" do
    it "wraps a synchronous computation" do
      effect = Ruby::Effect.sync { 1 + 1 }
      result = effect.run_sync
      expect(result).to eq(2)
    end

    it "captures defects" do
      effect = Ruby::Effect.sync { raise "boom" }
      expect { effect.run_sync }.to raise_error(Ruby::Effect::Error)
    end
  end

  describe ".try" do
    it "wraps a computation that might fail" do
      effect = Ruby::Effect.try { 10 / 2 }
      result = effect.run_sync
      expect(result).to eq(5)
    end

    it "catches errors" do
      effect = Ruby::Effect.try(catch_fn: ->(e) { "caught: #{e.message}" }) do
        raise "error"
      end
      expect { effect.run_sync }.to raise_error(Ruby::Effect::Error)
    end
  end

  describe "#map" do
    it "transforms the success value" do
      effect = Ruby::Effect.succeed(5).map { |x| x * 2 }
      result = effect.run_sync
      expect(result).to eq(10)
    end
  end

  describe "#flat_map" do
    it "chains effects" do
      effect = Ruby::Effect.succeed(5).flat_map { |x| Ruby::Effect.succeed(x * 2) }
      result = effect.run_sync
      expect(result).to eq(10)
    end
  end

  describe "#catch_all" do
    it "recovers from errors" do
      effect = Ruby::Effect.fail("error").catch_all { |_| Ruby::Effect.succeed("recovered") }
      result = effect.run_sync
      expect(result).to eq("recovered")
    end
  end

  describe "Context" do
    it "provides services to effects" do
      service = double("Service", call: "result")
      context = Ruby::Effect::Context.empty.add(:my_service, service)
      
      expect(context.get(:my_service)).to eq(service)
    end
  end

  describe "Option" do
    it "represents Some" do
      option = Ruby::Effect::Option.some(42)
      expect(option.some?).to be true
      expect(option.get_or_else(0)).to eq(42)
    end

    it "represents None" do
      option = Ruby::Effect::Option.none
      expect(option.none?).to be true
      expect(option.get_or_else(0)).to eq(0)
    end
  end

  describe "Either" do
    it "represents Right" do
      either = Ruby::Effect::Either.right(42)
      expect(either.right?).to be true
      expect(either.get_or_else(0)).to eq(42)
    end

    it "represents Left" do
      either = Ruby::Effect::Either.left("error")
      expect(either.left?).to be true
      expect(either.get_or_else(0)).to eq(0)
    end
  end

  describe "Duration" do
    it "creates durations from seconds" do
      duration = Ruby::Effect::Duration.seconds(5)
      expect(duration.to_seconds).to eq(5.0)
    end

    it "adds durations" do
      d1 = Ruby::Effect::Duration.seconds(3)
      d2 = Ruby::Effect::Duration.seconds(2)
      result = d1 + d2
      expect(result.to_seconds).to eq(5.0)
    end
  end

  describe "Queue" do
    it "offers and takes items" do
      queue = Ruby::Effect::Queue.unbounded.run_sync
      queue.offer(42).run_sync
      result = queue.take.run_sync
      expect(result).to eq(42)
    end
  end
end
