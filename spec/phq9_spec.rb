require_relative '../phq9'
require 'spec_helper'

RSpec.describe PHQ9Evaluator do
  empty = {}
  inc = { q1: 2, q3: 3, q5: 0, q9: 2 }
  inc = { q1: 2, q3: 3, q5: 0 }
  valid = { q1: 2, q2: 2, q3: 3, q4: 2, q5: 0, q6: 2, q7: 1, q8: 0, q9: 2,
            q10: 2 }
  wrong_range_sub = { q1: 2, q2: 2, q3: 3, q4: 2, q5: 0, q6: 2, q7: 4, q8: 0,
                      q9: 2, q10: 2 }
  wrong_range_pen = { q1: 2, q2: 2, q3: 3, q4: 2, q5: 0, q6: 2, q7: 4, q8: 0 }
  wrong_type_sub = { q1: 2, q2: 2, q3: 'hello', q4: 2, q5: 0, q6: 2, q7: 3,
                     q8: 0, q9: 2, q10: 2 }
  wrong_type_pen = { q1: 2, q2: 2, q3: 'hello', q4: 2, q5: 0, q6: 2, q7: 3 }
  excess_sub = { q1: 2, q2: 0, q3: 3, q4: 2, q5: 0, q6: 2, q7: 1, q8: 0, q9: 2,
                 q10: 2, q11: 2 }
  excess_pen = { q1: 2, q2: 0, q3: 3, q5: 0, q6: 2, q11: 2 }
  none = { q1: 0, q2: 1, q3: 0, q4: 1, q5: 0, q6: 0, q7: 1, q8: 0, q9: 0,
           q10: 0 }
  mild = { q1: 1, q2: 2, q3: 1, q4: 1, q5: 1, q6: 0, q7: 1, q8: 0, q9: 0,
           q10: 1 }
  mod_severe = { q1: 3, q2: 3, q3: 3, q4: 2, q5: 3, q6: 2, q7: 1, q8: 0, q9: 2,
                 q10: 2 }
  severe = { q1: 3, q2: 3, q3: 3, q4: 2, q5: 3, q6: 3, q7: 2, q8: 3, q9: 2,
             q10: 2 }

  let(:empty_sub_evaluator) { PHQ9Evaluator.new(empty, :submitted) }
  let(:empty_pen_evaluator) { PHQ9Evaluator.new(empty, :pending) }
  let(:inc_sub_evaluator) { PHQ9Evaluator.new(inc, :submitted) }
  let(:inc_pen_evaluator) { PHQ9Evaluator.new(inc, :pending) }
  let(:inc_pen_noq9_evaluator) { PHQ9Evaluator.new(inc_noq9, :pending) }
  let(:valid_sub_evaluator) { PHQ9Evaluator.new(valid, :submitted) }
  let(:valid_pen_evaluator) { PHQ9Evaluator.new(valid, :pending) }
  let(:wrong_range_sub_evaluator) do
    PHQ9Evaluator.new(wrong_range_sub, :submitted)
  end
  let(:wrong_range_pen_evaluator) do
    PHQ9Evaluator.new(wrong_range_pen, :pending)
  end
  let(:wrong_type_sub_evaluator) do
    PHQ9Evaluator.new(wrong_type_sub, :submitted)
  end
  let(:wrong_type_pen_evaluator) { PHQ9Evaluator.new(wrong_type_pen, :pending) }
  let(:excess_sub_evaluator) { PHQ9Evaluator.new(excess_sub, :submitted) }
  let(:excess_pen_evaluator) { PHQ9Evaluator.new(excess_pen, :pending) }
  let(:none_sub_evaluator) { PHQ9Evaluator.new(none, :submitted) }
  let(:none_pen_evaluator) { PHQ9Evaluator.new(none, :pending) }
  let(:mild_sub_evaluator) { PHQ9Evaluator.new(mild, :submitted) }
  let(:mild_pen_evaluator) { PHQ9Evaluator.new(mild, :pending) }
  let(:mod_severe_sub_evaluator) { PHQ9Evaluator.new(mod_severe, :submitted) }
  let(:mod_severe_pen_evaluator) { PHQ9Evaluator.new(mod_severe, :pending) }
  let(:severe_sub_evaluator) { PHQ9Evaluator.new(severe, :submitted) }
  let(:severe_pen_evaluator) { PHQ9Evaluator.new(severe, :pending) }

  describe 'validations' do
    context 'submitted' do
      it 'receives an empty hash' do
        expect(empty_sub_evaluator.valid?).to be_falsey
      end

      it 'receives an incomplete hash' do
        expect(inc_sub_evaluator.valid?).to be_falsey
        expect(inc_sub_evaluator.errors.messages[:q10])
          .to eq(["can't be blank", 'is not included in the list'])
      end

      it 'receives valid responses' do
        expect(valid_sub_evaluator.valid?).to be_truthy
        expect(valid_sub_evaluator.errors.messages)
          .to eq({})
      end

      it 'has a value outside the expected range' do
        expect(wrong_range_sub_evaluator.valid?).to be_falsey
        expect(wrong_range_sub_evaluator.errors[:q7])
          .to eq(['is not included in the list'])
      end

      it 'receives a disallowed key' do
        expect(excess_sub_evaluator.valid?).to be_falsey
        expect(excess_sub_evaluator.errors[:q11]).to eq(['forbidden key'])
      end

      it 'receives a value of the wrong type' do
        expect(wrong_type_sub_evaluator.valid?).to be_falsey
        expect(wrong_type_sub_evaluator.errors[:q3])
          .to eq(['is not included in the list'])
      end
    end

    context 'pending' do
      it 'receives an empty hash' do
        expect(empty_pen_evaluator.valid?).to be_truthy
      end

      it 'receives an incomplete hash' do
        expect(inc_pen_evaluator.valid?).to be_truthy
      end

      it 'receives valid responses' do
        expect(valid_pen_evaluator.valid?).to be_truthy
        expect(valid_pen_evaluator.errors.messages).to eq({})
      end

      it 'has a value outside the expected range' do
        expect(wrong_range_pen_evaluator.valid?).to be_falsey
        expect(wrong_range_pen_evaluator.errors[:q7])
          .to eq(['is not included in the list'])
      end

      it 'receives a disallowed key' do
        expect(excess_pen_evaluator.valid?).to be_falsey
        expect(excess_pen_evaluator.errors[:q11]).to eq(['forbidden key'])
      end

      it 'receives a value of the wrong type' do
        expect(wrong_type_pen_evaluator.valid?).to be_falsey
        expect(wrong_type_pen_evaluator.errors[:q3])
          .to eq(['is not included in the list'])
      end
    end
  end

  describe 'descriptor methods' do
    it 'is a screening object of type PHQ-9' do
      expect(valid_sub_evaluator.abbr).to eq('PHQ-9')
      expect(valid_sub_evaluator.disorder).to eq('Depression')
      expect(valid_sub_evaluator.max_score).to eq(27)
    end
  end

  describe 'scoring methods' do
    describe 'score_phq9' do
      context 'submitted' do
        it 'has responses that add to 14' do
          expect(valid_sub_evaluator.score_phq9).to eq(14)
        end
      end

      context 'pending' do
        it 'has responses that add to 14' do
          expect { valid_pen_evaluator.score_phq9 }
            .to raise_error(RuntimeError)
        end
      end
    end

    describe 'score_phq2' do
      context 'submitted' do
        it 'has responses to the first 2 questions that add to 4' do
          expect(valid_sub_evaluator.score_phq2).to eq(4)
        end
      end

      context 'pending' do
        it 'has responses to the first 2 questions that add to 4' do
          expect { valid_pen_evaluator.score_phq2 }
            .to raise_error(RuntimeError)
        end
      end
    end

    describe 'score' do
      context 'submitted' do
        it 'receives valid responses and is not instructed to return PHQ2' do
          expect(valid_sub_evaluator.score).to eq(14)
        end
      end

      context 'pending' do
        it 'receives a valid response hash, but is pending' do
          expect { valid_pen_evaluator.score }
            .to raise_error(RuntimeError)
        end
      end
    end
  end

  describe 'suicidal ideation' do
    context 'submitted' do
      it 'receives a valid response hash' do
        expect(valid_sub_evaluator.suic_ideation_score).to eq(2)
      end
    end

    context 'pending' do
      it 'receives a valid response hash and q9 is answered' do
        expect(inc_pen_evaluator.suic_ideation_score).to eq(2)
      end

      it 'receives a valid response hash but q9 is not answered' do
        expect { inc_pen_noq9_evaluator.suic_ideation_score }
          .to raise_error(RuntimeError)
      end
    end
  end

  describe 'phq2_positive?' do
    it 'has a high phq2' do
      expect(valid_sub_evaluator.phq2_positive?).to be_truthy
    end

    it 'has a low phq2' do
      expect(none_sub_evaluator.phq2_positive?).to be_falsey
    end
  end

  describe 'somewhat_depressed?' do
    it 'receives somewhat depressed responses' do
      expect(mild_sub_evaluator.somewhat_depressed?).to be_truthy
    end

    it 'receives not depressed responses' do
      expect(none_sub_evaluator.somewhat_depressed?).to be_falsey
    end
  end

  describe 'pretty_depressed?' do
    it 'receives pretty depressed responses' do
      expect(valid_sub_evaluator.pretty_depressed?).to be_truthy
    end

    it 'receives less than pretty depressed responses' do
      expect(mild_sub_evaluator.pretty_depressed?).to be_falsey
    end
  end

  describe 'impact?' do
    it 'receives impacted responses' do
      expect(valid_sub_evaluator.impact?).to be_truthy
    end

    it 'receives no impact responses' do
      expect(none_sub_evaluator.impact?).to be_falsey
    end
  end

  describe 'result' do
    it 'receives results that indicate substantial depression plus impact' do
      expect(valid_sub_evaluator.result).to be_truthy
    end

    it 'receives results that indicate mild depression' do
      expect(mild_sub_evaluator.result).to be_falsey
    end
  end

  describe 'answers' do
    it 'is a valid PHQ-9' do
      expect(valid_sub_evaluator.answers).to eq([2, 2, 3, 2, 0, 2, 1, 0, 2, 2])
    end
  end

  describe 'positive?' do
    it 'receives results that do not indicate depression' do
      expect(none_sub_evaluator.positive?).to be_falsey
    end

    it 'receives results that indicate at least mild depression' do
      expect(mild_sub_evaluator.positive?).to be_truthy
    end
  end

  describe 'eligible_for_spring_assessment?' do
    it 'receives results to mild for spring assessment' do
      expect(mild_sub_evaluator.eligible_for_spring_assessment?).to be_falsey
    end

    it 'receives results severe enough for spring assessment' do
      expect(valid_sub_evaluator.eligible_for_spring_assessment?).to be_truthy
    end
  end

  describe 'acuity and severity' do
    it 'receives results with no depression' do
      expect(none_sub_evaluator.severity).to eq('(minimal)')
      expect(none_sub_evaluator.acuity).to eq('none')
    end
    it 'receives results with mild depression' do
      expect(mild_sub_evaluator.severity).to eq('(mild)')
      expect(mild_sub_evaluator.acuity).to eq('mild')
    end
    it 'receives results with moderate depression' do
      expect(valid_sub_evaluator.severity).to eq('(moderate)')
      expect(valid_sub_evaluator.acuity).to eq('moderate')
    end
    it 'receives results with moderately severe depression' do
      expect(mod_severe_sub_evaluator.severity).to eq('(moderately severe)')
      expect(mod_severe_sub_evaluator.acuity).to eq('moderately severe')
    end
    it 'receives results with severe depression' do
      expect(severe_sub_evaluator.severity).to eq('(severe)')
      expect(severe_sub_evaluator.acuity).to eq('severe')
    end
  end
end
