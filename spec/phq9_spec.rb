require_relative '../phq9'
require 'spec_helper'

RSpec.describe PHQ9Evaluator do
  empty = {}
  inc = { q1: 2, q3: 3, q5: 0 }
  valid = { q1: 2, q2: 2, q3: 3, q4: 2, q5: 0, q6: 2, q7: 1, q8: 0, q9: 2,
            q10: 2 }
  wrong_range = { q1: 2, q2: 2, q3: 3, q4: 2, q5: 0, q6: 2, q7: 4, q8: 0, q9: 2,
            q10: 2 }
  wrong_type = { q1: 2, q2: 2, q3: 'hello', q4: 2, q5: 0, q6: 2, q7: 4, q8: 0, q9: 2,
                 q10: 2 }
  excess = { q1: 2, q2: 0, q3: 3, q4: 2, q5: 0, q6: 2, q7: 1, q8: 0, q9: 2,
             q10: 2, q11: 2 }
  none = { q1: 0, q2: 1, q3: 0, q4: 1, q5: 0, q6: 0, q7: 1, q8: 0, q9: 0,
           q10: 0 }
  mild = { q1: 1, q2: 2, q3: 1, q4: 1, q5: 1, q6: 0, q7: 1, q8: 0, q9: 0,
           q10: 1 }
  mod_severe = { q1: 3, q2: 3, q3: 3, q4: 2, q5: 3, q6: 2, q7: 1, q8: 0, q9: 2,
                 q10: 2 }
  severe = { q1: 3, q2: 3, q3: 3, q4: 2, q5: 3, q6: 3, q7: 2, q8: 3, q9: 2,
             q10: 2 }

  let(:empty_evaluator) { PHQ9Evaluator.new(empty) }
  let(:inc_evaluator) { PHQ9Evaluator.new(inc) }
  let(:valid_evaluator) { PHQ9Evaluator.new(valid) }
  let(:wrong_range_evaluator) { PHQ9Evaluator.new(wrong_range) }
  let(:wrong_type_evaluator) { PHQ9Evaluator.new(wrong_type) }
  let(:excess_evaluator) { PHQ9Evaluator.new(excess) }
  let(:none_evaluator) { PHQ9Evaluator.new(none) }
  let(:mild_evaluator) { PHQ9Evaluator.new(mild) }
  let(:mod_severe_evaluator) { PHQ9Evaluator.new(mod_severe) }
  let(:severe_evaluator) { PHQ9Evaluator.new(severe) }

  describe 'validations' do
    it 'receives an empty hash' do
      expect(empty_evaluator.valid?).to be_falsey
    end

    it 'receives an incomplete hash' do
      expect(inc_evaluator.valid?).to be_falsey
      expect(inc_evaluator.errors.messages[:q10]).to eq(['response not found'])
    end

    it 'receives valid responses' do
      expect(valid_evaluator.valid?).to be_truthy
      expect(valid_evaluator.errors.messages).to eq({})
    end

    it 'has a value outside the expected range' do
      expect(wrong_range_evaluator.valid?).to be_falsey
      expect(wrong_range_evaluator.errors[:q7]).to eq(['range error'])
    end

    it 'receives a disallowed key' do
      expect(excess_evaluator.valid?).to be_falsey
      expect(excess_evaluator.errors[:q11]).to eq(['invalid key'])
    end

    it 'receives a value of the wrong type' do
      expect(wrong_type_evaluator.valid?).to be_falsey
      expect(wrong_type_evaluator.errors[:q7]).to eq(['type error'])
    end
  end

  describe 'descriptor methods' do
    it 'is a screening object of type PHQ-9' do
      expect(valid_evaluator.abbr).to eq('PHQ-9')
      expect(valid_evaluator.disorder).to eq('Depression')
      expect(valid_evaluator.max_score).to eq(27)
    end
  end

  describe 'scoring methods' do
    describe 'score_phq9' do
      it 'has responses that add to 14' do
        expect(valid_evaluator.score_phq9).to eq(14)
      end
    end

    describe 'score_phq2' do
      it 'has responses to the first 2 questions that add to 4' do
        expect(valid_evaluator.score_phq2).to eq(4)
      end
    end

    describe 'score' do
      it 'does returns PHQ9 score when not instructed to return PHQ2' do
        expect(valid_evaluator.score).to eq(14)
      end
    end
  end

  describe 'suicidal ideation' do
    it 'returns a suicidal ideation score' do
      expect(valid_evaluator.suic_ideation_score).to eq(2)
    end
  end

  describe 'phq2_positive?' do
    it 'has a high phq2' do
      expect(valid_evaluator.phq2_positive?).to be_truthy
    end

    it 'has a low phq2' do
      expect(none_evaluator.phq2_positive?).to be_falsey
    end
  end

  describe 'somewhat_depressed?' do
    it 'receives somewhat depressed responses' do
      expect(mild_evaluator.somewhat_depressed?).to be_truthy
    end

    it 'receives not depressed responses' do
      expect(none_evaluator.somewhat_depressed?).to be_falsey
    end
  end

  describe 'pretty_depressed?' do
    it 'receives pretty depressed responses' do
      expect(valid_evaluator.pretty_depressed?).to be_truthy
    end

    it 'receives less than pretty depressed responses' do
      expect(mild_evaluator.pretty_depressed?).to be_falsey
    end
  end

  describe 'impact?' do
    it 'receives impacted responses' do
      expect(valid_evaluator.impact?).to be_truthy
    end

    it 'receives no impact responses' do
      expect(none_evaluator.impact?).to be_falsey
    end
  end

  describe 'result' do
    it 'receives results that indicate substantial depression plus impact' do
      expect(valid_evaluator.result).to be_truthy
    end

    it 'receives results that indicate mild depression' do
      expect(mild_evaluator.result).to be_falsey
    end
  end

  describe 'answers' do
    it 'is a valid PHQ-9' do
      expect(valid_evaluator.answers).to eq([2, 2, 3, 2, 0, 2, 1, 0, 2, 2])
    end
  end

  describe 'positive?' do
    it 'receives results that do not indicate depression' do
      expect(none_evaluator.positive?).to be_falsey
    end

    it 'receives results that indicate at least mild depression' do
      expect(mild_evaluator.positive?).to be_truthy
    end
  end

  describe 'eligible_for_spring_assessment?' do
    it 'receives results to mild for spring assessment' do
      expect(mild_evaluator.eligible_for_spring_assessment?).to be_falsey
    end

    it 'receives results severe enough for spring assessment' do
      expect(valid_evaluator.eligible_for_spring_assessment?).to be_truthy
    end
  end

  describe 'acuity and severity' do
    it 'receives results with no depression' do
      expect(none_evaluator.severity).to eq('(minimal)')
      expect(none_evaluator.acuity).to eq('none')
    end
    it 'receives results with mild depression' do
      expect(mild_evaluator.severity).to eq('(mild)')
      expect(mild_evaluator.acuity).to eq('mild')
    end
    it 'receives results with moderate depression' do
      expect(valid_evaluator.severity).to eq('(moderate)')
      expect(valid_evaluator.acuity).to eq('moderate')
    end
    it 'receives results with moderately severe depression' do
      expect(mod_severe_evaluator.severity).to eq('(moderately severe)')
      expect(mod_severe_evaluator.acuity).to eq('moderately severe')
    end
    it 'receives results with severe depression' do
      expect(severe_evaluator.severity).to eq('(severe)')
      expect(severe_evaluator.acuity).to eq('severe')
    end
  end
end
