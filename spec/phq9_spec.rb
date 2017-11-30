require_relative '../phq9'
require_relative '../response_validator'
require 'spec_helper'

RSpec.describe PHQ9Evaluator do
  let(:evaluator) { PHQ9Evaluator.new(responses, status) }
  let(:evaluator_errors) { evaluator.valid? ? {} : evaluator.errors }

  context 'with an empty response hash' do
    let(:responses) { {} }
    errors = ["can't be blank", 'is not included in the list']
    context 'pending' do
      let(:status) { :pending }
      specify { expect(evaluator).to be_valid }
    end
    context 'submitted' do
      let(:status) { :submitted }
      specify { expect(evaluator).not_to be_valid }
      specify { expect(evaluator_errors[:q1]).to eq(errors) }
    end
  end

  context 'with a hash that includes a disallowed key' do
    hash = { q1: 2, q3: 3, q4: 2, q5: 0, q6: 2, q7: 1, q8: 0, q9: 2, q10: 2,
             q11: 2 }
    let(:responses) { hash }
    context 'pending' do
      let(:status) { :pending }
      specify { expect(evaluator_errors[:q11]).to eq(['forbidden key']) }
      specify { expect(evaluator.abbr).to eq('PHQ-9') }
      specify { expect(evaluator.disorder).to eq('Depression') }
      specify { expect(evaluator.max_score).to eq(27) }
    end
    context 'submitted' do
      let(:status) { :submitted }
      specify { expect(evaluator_errors[:q11]).to eq(['forbidden key']) }
    end
  end

  context 'with a value outside accepted range' do
    hash = { q1: 2, q3: 3, q4: 2, q5: 0, q6: 2, q7: 4, q8: 0, q9: 2, q10: 2 }
    let(:responses) { hash }
    context 'pending' do
      let(:status) { :pending }
      errors = ['is not included in the list']
      specify { expect(evaluator_errors[:q7]).to eq(errors) }
    end
  end

  context 'with a set of responses missing q2' do
    hash = { q1: 2, q3: 3, q4: 2, q5: 0, q6: 2, q7: 1, q8: 0, q9: 2, q10: 2 }
    let(:responses) { hash }
    context 'pending' do
      let(:status) { :pending }
      it '' do
        expect { evaluator.score }.to raise_error(ResponseNotReadyError)
        expect { evaluator.score_phq2 }.to raise_error(ResponseNotReadyError)
        expect { evaluator.score_phq9 }.to raise_error(ResponseNotReadyError)
        expect { evaluator.phq2_positive? }.to raise_error(InvalidResponseError)
        expect { evaluator.somewhat_depressed? }
          .to raise_error(InvalidResponseError)
      end
    end
    context 'submitted' do
      let(:status) { :submitted }
      it '' do
        expect { evaluator.score }.to raise_error(InvalidResponseError)
        expect { evaluator.score_phq2 }.to raise_error(InvalidResponseError)
        expect { evaluator.score_phq9 }.to raise_error(InvalidResponseError)
      end
    end
  end

  context 'with a set of responses missing q9' do
    hash = { q1: 2, q2: 2, q3: 3, q4: 2, q5: 0, q6: 2, q7: 1, q8: 0, q10: 2 }
    let(:responses) { hash }
    context 'pending' do
      let(:status) { :pending }
      specify { expect(evaluator.impact?).to be_truthy }
      specify { expect(evaluator.somewhat_depressed?).to be_truthy }
      it '' do
        expect { evaluator.suic_ideation_score }
          .to raise_error(InvalidResponseError)
        expect { evaluator.pretty_depressed? }
          .to raise_error(InvalidResponseError)
      end
    end
    context 'submitted' do
      let(:status) { :submitted }
      it '' do
        expect { evaluator.impact? }.to raise_error(InvalidResponseError)
      end
    end
  end

  context 'with a set of responses missing q10' do
    hash = { q1: 2, q2: 2, q3: 3, q4: 2, q5: 0, q6: 2, q7: 1, q8: 0, q9: 2 }
    let(:responses) { hash }
    context 'pending' do
      let(:status) { :pending }
      it '' do
        expect { evaluator.impact? }.to raise_error(InvalidResponseError)
      end
      specify { expect(evaluator.pretty_depressed?).to be_truthy }
      specify { expect(evaluator.suic_ideation_score).to eq(2) }
    end
    context 'submitted' do
      let(:status) { :submitted }
      errors = ["can't be blank", 'is not included in the list']
      specify { expect(evaluator_errors[:q10]).to eq(errors) }
      it '' do
        expect { evaluator.pretty_depressed? }
          .to raise_error(InvalidResponseError)
        expect { evaluator.suic_ideation_score }
          .to raise_error(InvalidResponseError)
      end
    end
  end

  context 'with a full set of responses indicating no depression' do
    hash = { q1: 0, q2: 1, q3: 0, q4: 1, q5: 0, q6: 0, q7: 1, q8: 0, q9: 0,
             q10: 0 }
    let(:responses) { hash }
    context 'pending' do
      let(:status) { :pending }
      it '' do
        expect { evaluator.score }.to raise_error(ResponseNotReadyError)
        expect { evaluator.score_phq9 }.to raise_error(ResponseNotReadyError)
        expect { evaluator.score_phq2 }.to raise_error(ResponseNotReadyError)
      end
      specify { expect(evaluator.phq2_positive?).to be_falsey }
      specify { expect(evaluator.impact?).to be_falsey }
      specify { expect(evaluator.somewhat_depressed?).to be_falsey }
    end
    context 'submitted' do
      let(:status) { :submitted }
      specify { expect(evaluator).to be_valid }
      specify { expect(evaluator.acuity).to eq('none') }
      specify { expect(evaluator.severity).to eq('(minimal)') }
      specify { expect(evaluator.positive?).to be_falsey }
      specify { expect(evaluator.score).to eq(3) }
      specify { expect(evaluator.score_phq9).to eq(3) }
      specify { expect(evaluator.score_phq2).to eq(1) }
      specify { expect(evaluator.answers).to eq [0, 1, 0, 1, 0, 0, 1, 0, 0, 0] }
    end
  end

  context 'with a full set of responses indicating mild depression' do
    hash = { q1: 1, q2: 2, q3: 1, q4: 1, q5: 1, q6: 0, q7: 1, q8: 0, q9: 0,
             q10: 1 }
    let(:responses) { hash }
    context 'pending' do
      let(:status) { :pending }
      specify { expect(evaluator.phq2_positive?).to be_truthy }
      specify { expect(evaluator.impact?).to be_truthy }
      specify { expect(evaluator.somewhat_depressed?).to be_truthy }
      specify { expect(evaluator.pretty_depressed?).to be_falsey }
    end
    context 'submitted' do
      let(:status) { :submitted }
      specify { expect(evaluator.acuity).to eq('mild') }
      specify { expect(evaluator.severity).to eq('(mild)') }
      specify { expect(evaluator.positive?).to be_truthy }
      specify { expect(evaluator.result).to be_falsey }
      specify { expect(evaluator.eligible_for_spring_assessment?).to be_falsey }
    end
  end

  context 'with a full set of responses indicating moderate depression' do
    hash = { q1: 2, q2: 2, q3: 3, q4: 2, q5: 0, q6: 2, q7: 1, q8: 0, q9: 2,
             q10: 2 }
    let(:responses) { hash }

    context 'submitted' do
      let(:status) { :submitted }
      specify { expect(evaluator.acuity).to eq('moderate') }
      specify { expect(evaluator.severity).to eq('(moderate)') }
      specify { expect(evaluator.pretty_depressed?).to be_truthy }
      specify { expect(evaluator.result).to be_truthy }
      specify { expect(evaluator.eligible_for_spring_assessment?).to be_truthy }
    end
  end

  context 'with a full set of responses indicating mod-severe depression' do
    hash = { q1: 3, q2: 3, q3: 3, q4: 2, q5: 3, q6: 2, q7: 1, q8: 0, q9: 2,
             q10: 2 }
    let(:responses) { hash }
    context 'submitted' do
      let(:status) { :submitted }
      specify { expect(evaluator.acuity).to eq('moderately severe') }
      specify { expect(evaluator.severity).to eq('(moderately severe)') }
    end
  end

  context 'with a full set of responses indicating severe depression' do
    hash = { q1: 3, q2: 3, q3: 3, q4: 2, q5: 3, q6: 3, q7: 2, q8: 3, q9: 2,
             q10: 2 }
    let(:responses) { hash }
    context 'submitted' do
      let(:status) { :submitted }
      specify { expect(evaluator.acuity).to eq('severe') }
      specify { expect(evaluator.severity).to eq('(severe)') }
    end
  end
end
