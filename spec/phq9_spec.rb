require_relative '../phq9'
require 'spec_helper'

RSpec.describe PHQ9Evaluator do
  empty, inc, valid, wrong, excess =
    {}, { q1: 2, q3: 3, q5: 0 },
    { q1: 2, q2: 0, q3: 3, q4: 2, q5: 0, q6: 2, q7: 1, q8: 0, q9: 2, q10: 2 },
    { q1: 2, q2: 0, q3: 3, q4: 2, q5: 0, q6: 2, q7: 4, q8: 0, q9: 2, q10: 2 },
    { q1: 2, q2: 0, q3: 3, q4: 2, q5: 0, q6: 2, q7: 4, q8: 0, q9: 2, q10: 2 },
    { q1: 2, q2: 0, q3: 3, q4: 2, q5: 0, q6: 2, q7: 1, q8: 0, q9: 2, q10: 2,
      q11: 2 }

  before(:each) do
    @empty_evaluator = PHQ9Evaluator.new(empty)
    @inc_evaluator = PHQ9Evaluator.new(inc)
    @valid_evaluator = PHQ9Evaluator.new(valid)
    @wrong_evaluator = PHQ9Evaluator.new(wrong)
    @excess_evaluator = PHQ9Evaluator.new(excess)
  end
  it 'is invalid if it receives an empty hash' do
    expect(@empty_evaluator.valid?).to be_falsey
  end

  it 'is invalid if it receives an inc hash' do
    expect(@inc_evaluator.valid?).to be_falsey
  end

  it 'is valid if it receives a complete hash' do
    expect(@valid_evaluator.valid?).to be_truthy
  end

  it 'is invalid if a value is outside the expected range' do
    expect(@wrong_evaluator.valid?).to be_falsey
  end

  it 'is invalid if it receives a disallowed key' do
    expect(@excess_evaluator.valid?).to be_falsey
  end

  it 'returns nil for a score if responses are invalid' do
    expect(@inc_evaluator.score).to eq(nil)
  end

  it 'returns the score for valid responses' do
    expect(@valid_evaluator.score).to eq(12)
  end

  it 'returns an empty array for errors if valid? has never been called' do
    expect(@inc_evaluator.errors).to eq({})
  end

  it 'returns empty array for errors on a valid array after calling valid?' do
    @valid_evaluator.valid?
    expect(@valid_evaluator.errors).to eq({})
  end

  it 'returns array for errors if valid called on invalid array' do
    @inc_evaluator.valid?
    expect(@inc_evaluator.errors[:q10]).to eq(['That response does not exist'])
  end
end
