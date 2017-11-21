require_relative '../phq9'
require 'spec_helper'

RSpec.describe PHQ9Evaluator do
  empty = {}
  inc = { q1: 2, q3: 3, q5: 0 }
  valid = { q1: 2, q2: 2, q3: 3, q4: 2, q5: 0, q6: 2, q7: 1, q8: 0, q9: 2,
            q10: 2 }
  wrong = { q1: 2, q2: 2, q3: 3, q4: 2, q5: 0, q6: 2, q7: 4, q8: 0, q9: 2,
            q10: 2 }
  excess = { q1: 2, q2: 0, q3: 3, q4: 2, q5: 0, q6: 2, q7: 1, q8: 0, q9: 2,
             q10: 2, q11: 2 }
  none = { q1: 0, q2: 1, q3: 0, q4: 1, q5: 0, q6: 0, q7: 1, q8: 0, q9: 0,
           q10: 1 }
  mild = { q1: 1, q2: 2, q3: 1, q4: 1, q5: 1, q6: 0, q7: 1, q8: 0, q9: 0,
           q10: 1 }

  let(:empty_evaluator) { PHQ9Evaluator.new(empty) }
  let(:inc_evaluator) { PHQ9Evaluator.new(inc) }
  let(:valid_evaluator) { PHQ9Evaluator.new(valid) }
  let(:wrong_evaluator) { PHQ9Evaluator.new(wrong) }
  let(:excess_evaluator) { PHQ9Evaluator.new(excess) }
  let(:none_evaluator) { PHQ9Evaluator.new(none) }
  let(:mild_evaluator) { PHQ9Evaluator.new(mild) }

  describe 'valid?' do
    it 'receives an empty hash' do
      expect(empty_evaluator.valid?).to be_falsey
    end

    it 'receives an incomplete hash' do
      expect(inc_evaluator.valid?).to be_falsey
    end

    it 'receives a complete hash' do
      expect(valid_evaluator.valid?).to be_truthy
    end

    it 'has a value outside the expected range' do
      expect(wrong_evaluator.valid?).to be_falsey
    end

    it 'receives a disallowed key' do
      expect(excess_evaluator.valid?).to be_falsey
    end
  end

  describe 'errors' do
    it 'responses are valid' do
      expect(valid_evaluator.errors.messages).to eq({})
    end

    it 'is called on invalid array' do
      inc_evaluator.valid?
      expect(inc_evaluator.errors.messages[:q10]).to eq(['not answered'])
    end
  end

  describe 'score' do
    it 'returns nil for a score if responses are invalid' do
      expect(inc_evaluator.score).to eq(nil)
    end

    it 'responses are valid and add to 14' do
      expect(valid_evaluator.score).to eq(14)
    end
  end

  describe 'acuity' do
    it 'receives a response set with no depression' do
      expect(none_evaluator.acuity).to eq('none')
    end
  end

  it 'receives a response set with mild depression' do
    expect(mild_evaluator.acuity).to eq('mild')
  end

  it 'returns a suicidal ideation score' do
    expect(valid_evaluator.suic_ideation_score).to eq(2)
  end

  it 'has a positive phq2' do
    expect(valid_evaluator.phq2_positive?).to be_truthy
  end

  it 'has a negative phq2' do
    expect(none_evaluator.phq2_positive?).to be_falsey
  end

  it 'has a true step1' do
    expect(mild_evaluator.step1?).to be_truthy
  end
end
