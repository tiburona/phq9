require_relative '../phq9'
require_relative '../response_validator'
require 'spec_helper'

RSpec.describe PHQ9Evaluator do
  let(:subject) { PHQ9Evaluator.new(responses, status) }
  let(:subject_errors) { subject.valid? ? {} : subject.errors }

  context 'with an empty response hash' do
    let(:responses) { {} }
    errors = ["can't be blank", 'is not included in the list']
    context 'pending' do
      let(:status) { :pending }
      specify { is_expected.to be_valid }
    end
    context 'submitted' do
      let(:status) { :submitted }
      specify { is_expected.not_to be_valid }
      specify { expect(subject_errors[:q1]).to eq(errors) }
    end
  end

  context 'with a hash that includes a disallowed key' do
    hash = { q1: 2, q3: 3, q4: 2, q5: 0, q6: 2, q7: 1, q8: 0, q9: 2, q10: 2,
             q11: 2 }
    let(:responses) { hash }
    context 'pending' do
      let(:status) { :pending }
      specify { expect(subject_errors[:q11]).to eq(['forbidden key']) }
    end
    context 'submitted' do
      let(:status) { :submitted }
      specify { expect(subject_errors[:q11]).to eq(['forbidden key']) }
    end
  end

  context 'with a value outside accepted range' do
    hash = { q1: 2, q3: 3, q4: 2, q5: 0, q6: 2, q7: 4, q8: 0, q9: 2, q10: 2 }
    let(:responses) { hash }
    context 'pending' do
      let(:status) { :pending }
      errors = ['is not included in the list']
      specify { expect(subject_errors[:q7]).to eq(errors) }
    end
  end

  context 'with a set of responses missing q9' do
    hash = { q1: 2, q2: 2, q3: 3, q4: 2, q5: 0, q6: 2, q7: 1, q8: 0, q10: 2 }
    let(:responses) { hash }
    context 'pending' do
      let(:status) { :pending }
      it 'raises invalid errors on methods that require q9' do
        expect { subject.suic_ideation_score }
          .to raise_error(InvalidResponseError)
      end
    end
  end

  context 'with a missing response (but not q9)' do
    hash = { q1: 2, q2: 2, q3: 3, q4: 2, q5: 0, q6: 2, q7: 1, q8: 0, q9: 2 }
    let(:responses) { hash }
    context 'pending' do
      let(:status) { :pending }
      it 'returns a suicidal ideation score even for incomplete responses' do
        expect(subject.suic_ideation_score).to eq(2)
      end
    end
  end

  context 'with a full set of responses' do
    hash = { q1: 0, q2: 1, q3: 0, q4: 1, q5: 0, q6: 0, q7: 1, q8: 0, q9: 0,
             q10: 0 }
    let(:responses) { hash }
    context 'pending' do
      let(:status) { :pending }
      specify { is_expected.to be_valid }
      it 'raises not ready errors on final score methods' do
        expect { subject.score }.to raise_error(ResponseNotReadyError)
        expect { subject.score_phq9 }.to raise_error(ResponseNotReadyError)
        expect { subject.score_phq2 }.to raise_error(ResponseNotReadyError)
      end
    end
    context 'submitted' do
      let(:status) { :submitted }
      specify { is_expected.to be_valid }
      specify { expect(subject.score).to eq(3) }
      specify { expect(subject.score_phq9).to eq(3) }
      specify { expect(subject.score_phq2).to eq(1) }
      specify { expect(subject.answers).to eq [0, 1, 0, 1, 0, 0, 1, 0, 0, 0] }
    end
  end

  context 'with a full set of responses indicating no depression' do
    hash = { q1: 0, q2: 1, q3: 0, q4: 1, q5: 0, q6: 0, q7: 1, q8: 0, q9: 0,
             q10: 0 }
    let(:responses) { hash }
    context 'submitted' do
      let(:status) { :submitted }
      specify { is_expected.not_to be_impacted }
      specify { is_expected.not_to be_positive }
      specify { is_expected.not_to be_phq2_positive }
      specify { expect(subject.acuity).to eq('none') }
      specify { expect(subject.severity).to eq('(minimal)') }
    end
  end

  context 'with a full set of responses indicating mild depression' do
    hash = { q1: 1, q2: 2, q3: 1, q4: 1, q5: 1, q6: 0, q7: 1, q8: 0, q9: 0,
             q10: 1 }
    let(:responses) { hash }
    context 'submitted' do
      let(:status) { :submitted }
      specify { expect(subject.acuity).to eq('mild') }
      specify { expect(subject.severity).to eq('(mild)') }
      specify { is_expected.to be_positive }
      specify { expect(subject.result).to be_falsey }
      specify { is_expected.not_to be_pretty_depressed }
      specify { is_expected.not_to be_eligible_for_spring_assessment }
    end
  end

  context 'with a full set of responses indicating moderate depression' do
    hash = { q1: 2, q2: 2, q3: 3, q4: 2, q5: 0, q6: 2, q7: 1, q8: 0, q9: 2,
             q10: 2 }
    let(:responses) { hash }
    context 'submitted' do
      let(:status) { :submitted }
      specify { expect(subject.acuity).to eq('moderate') }
      specify { expect(subject.severity).to eq('(moderate)') }
      specify { is_expected.to be_pretty_depressed }
      specify { expect(subject.result).to be_truthy }
      specify { is_expected.to be_eligible_for_spring_assessment }
    end
  end

  context 'with a full set of responses indicating mod-severe depression' do
    hash = { q1: 3, q2: 3, q3: 3, q4: 2, q5: 3, q6: 2, q7: 1, q8: 0, q9: 2,
             q10: 2 }
    let(:responses) { hash }
    context 'submitted' do
      let(:status) { :submitted }
      specify { expect(subject.acuity).to eq('moderately severe') }
      specify { expect(subject.severity).to eq('(moderately severe)') }
    end
  end

  context 'with a full set of responses indicating severe depression' do
    hash = { q1: 3, q2: 3, q3: 3, q4: 2, q5: 3, q6: 3, q7: 2, q8: 3, q9: 2,
             q10: 2 }
    let(:responses) { hash }
    context 'submitted' do
      let(:status) { :submitted }
      specify { expect(subject.acuity).to eq('severe') }
      specify { expect(subject.severity).to eq('(severe)') }
    end
  end
end
