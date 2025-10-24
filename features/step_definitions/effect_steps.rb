Given('I create an effect that succeeds with value {int}') do |value|
  @effect = Ruby::Effect.succeed(value)
end

Given('I create an effect that fails with error {string}') do |error_message|
  @effect = Ruby::Effect.fail(error_message)
end

When('I run the effect synchronously') do
  @result = @effect.run_sync
end

When('I attempt to run the effect synchronously') do
  begin
    @effect.run_sync
    @error_raised = false
  rescue Ruby::Effect::Error
    @error_raised = true
  end
end

When('I map the effect with a function that doubles the value') do
  @effect = @effect.map { |x| x * 2 }
end

When('I flat_map the effect with a function that returns an effect of the value times {int}') do |multiplier|
  @effect = @effect.flat_map { |x| Ruby::Effect.succeed(x * multiplier) }
end

When('I catch all errors and recover with value {string}') do |recovery_value|
  @effect = @effect.catch_all { |_| Ruby::Effect.succeed(recovery_value) }
end

Then('the result should be {int}') do |expected_value|
  expect(@result).to eq(expected_value)
end

Then('the result should be {string}') do |expected_value|
  expect(@result).to eq(expected_value)
end

Then('it should raise an error') do
  expect(@error_raised).to be true
end

