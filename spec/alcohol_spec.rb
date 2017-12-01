require_relative '../alcohol'
require_relative '../custom_validation_errors'
require 'active_model'
require 'spec_helper'

RSpec.describe AlcoholScreeningEvaluator do
  let(:subject) { AlcoholScreeningEvaluator.new(responses, status) }
  let(:subject_errors) { subject.valid? ? {} : subject.errors }

  context 'with an empty response hash' do
    let(:responses) { {} }
    errors = ["can't be blank", 'is not included in the list']
    context 'requested' do
      let(:status) { :requested }
      specify { is_expected.to be_valid }
    end
    context 'started' do
      let(:status) { :started }
      specify { is_expected.to be_valid }
    end
    context 'finished' do
      let(:status) { :finished }
      specify { is_expected.not_to be_valid }
      specify { expect(subject_errors[:q1]).to eq(errors) }
    end
  end

  context 'with a hash that includes a disallowed key' do
    hash = { q1: 2, q3: 3, q4: 2, q5: 0, q6: 2, q7: 1, q8: 0, q9: 2, q10: 2,
             q11: 2 }
    let(:responses) { hash }
    context 'started' do
      let(:status) { :started }
      specify { is_expected.not_to be_valid }
      specify { expect(subject_errors[:q11]).to eq(['invalid key']) }
    end
  end

  context 'with a value outside accepted range' do
    hash = { q1: 2, q3: 3, q4: 2, q5: 0, q6: 2, q7: 5, q8: 0, q9: 2, q10: 2 }
    let(:responses) { hash }
    context 'started' do
      let(:status) { :started }
      errors = ['is not included in the list']
      specify { expect(subject_errors[:q7]).to eq(errors) }
    end
  end

  context 'with a full set of responses' do
    hash = { q1: 0, q2: 1, q3: 0, q4: 1, q5: 0, q6: 0, q7: 1, q8: 0, q9: 0,
             q10: 0 }
    let(:responses) { hash }
    context 'requested' do
      let(:status) { :requested }
      specify { is_expected.not_to be_valid }
    end
    context 'started' do
      let(:status) { :started }
      specify { is_expected.to be_valid }
      it 'raises not ready errors on final score methods' do
        expect { subject.score }.to raise_error(ResponseNotReadyError)
        expect { subject.positive? }.to raise_error(ResponseNotReadyError)
        expect { subject.acuity }.to raise_error(ResponseNotReadyError)
      end
    end
    context 'finished' do
      let(:status) { :finished }
      specify { is_expected.to be_valid }
      specify { expect(subject.score).to eq(3) }
      specify { expect(subject.answers).to eq [0, 1, 0, 1, 0, 0, 1, 0, 0, 0] }
    end
  end

  context 'with responses not indicating an alcohol problem' do
    hash = { q1: 0, q2: 1, q3: 0, q4: 1, q5: 0, q6: 0, q7: 1, q8: 0, q9: 0,
             q10: 0 }
    let(:responses) { hash }
    context 'finished' do
      let(:status) { :finished }
      specify { is_expected.not_to be_positive }
      specify { is_expected.not_to be_auditcpositive }
      specify { expect(subject.acuity).to eq('none') }
    end
  end

  context 'with responses indicating harmful consumption' do
    hash = { q1: 2, q2: 1, q3: 0, q4: 1, q5: 2, q6: 3, q7: 1, q8: 0, q9: 0,
             q10: 3 }
    let(:responses) { hash }
    context 'finished' do
      let(:status) { :finished }
      specify { is_expected.to be_positive }
      specify { is_expected.to be_auditcpositive }
      specify { expect(subject.acuity).to eq 'hazardous/harmful alcohol consumption' }
    end
  end

  context 'with responses indicating high problems' do
    hash = { q1: 1, q2: 4, q3: 1, q4: 1, q5: 2, q6: 2, q7: 2, q8: 1, q9: 0,
             q10: 3 }
    let(:responses) { hash }
    context 'finished' do
      let(:status) { :finished }
      specify { is_expected.to be_positive }
      specify { is_expected.to be_auditcpositive }
      specify { expect(subject.acuity).to eq 'high level of alcohol problems' }
    end
  end

  context 'with responses indicating dependence' do
    hash = { q1: 3, q2: 4, q3: 1, q4: 3, q5: 2, q6: 4, q7: 2, q8: 1, q9: 0,
             q10: 3 }
    let(:responses) { hash }
    context 'finished' do
      let(:status) { :finished }
      specify { expect(subject.acuity).to eq 'probable alcohol dependence' }
    end
  end
end
