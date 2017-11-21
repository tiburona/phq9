require_relative '../phq9'
require 'spec_helper'

RSpec.describe PHQ9Evaluator do
  empty, inc, valid, wrong, excess, none, mild =
    {}, { q1: 2, q3: 3, q5: 0 },
    { q1: 2, q2: 0, q3: 3, q4: 2, q5: 0, q6: 2, q7: 1, q8: 0, q9: 2, q10: 2 },
    { q1: 2, q2: 0, q3: 3, q4: 2, q5: 0, q6: 2, q7: 4, q8: 0, q9: 2, q10: 2 },
    { q1: 2, q2: 0, q3: 3, q4: 2, q5: 0, q6: 2, q7: 1, q8: 0, q9: 2, q10: 2,
      q11: 2 },
    { q1: 0, q2: 1, q3: 0, q4: 1, q5: 0, q6: 0, q7: 1, q8: 0, q9: 0, q10: 1 },
    { q1: 1, q2: 1, q3: 1, q4: 1, q5: 1, q6: 0, q7: 1, q8: 0, q9: 0, q10: 1 }

  before(:each) do
    @empty_evaluator = PHQ9Evaluator.new(empty)
    @inc_evaluator = PHQ9Evaluator.new(inc)
    @valid_evaluator = PHQ9Evaluator.new(valid)
    @wrong_evaluator = PHQ9Evaluator.new(wrong)
    @excess_evaluator = PHQ9Evaluator.new(excess)
    @none_evaluator = PHQ9Evaluator.new(none)
    @mild_evaluator = PHQ9Evaluator.new(mild)
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

  it 'returns empty array for errors on a valid array' do
    expect(@valid_evaluator.errors.messages).to eq({})
  end

  it 'returns array for errors if valid called on invalid array' do
    @inc_evaluator.valid?
    expect(@inc_evaluator.errors.messages[:q10]).to eq(['not answered'])
  end

  it 'returns none acuity for a response set with no depression' do
    expect(@none_evaluator.acuity).to eq('none')
  end

  it 'returns mild acuity for a response set with mild depression' do
    expect(@mild_evaluator.acuity).to eq('mild')
  end

  it 'returns a suicidal ideation score' do
    expect(@valid_evaluator.suic_ideation_score).to eq(2)
  end
end
