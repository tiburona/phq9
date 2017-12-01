require_relative '../asrs'
require_relative '../custom_validation_errors'
require 'active_model'
require 'spec_helper'

RSpec.describe ASRSEvaluator do
  let(:subject) { ASRSEvaluator.new(responses, status) }
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
    hash = { q1: 2, q3: 3, q4: 2, q5: 0, q6: 2, q7: 1 }
    let(:responses) { hash }
    context 'started' do
      let(:status) { :started }
      specify { is_expected.not_to be_valid }
      specify { expect(subject_errors[:q7]).to eq(['invalid key']) }
    end
  end

  context 'with a value outside accepted range' do
    hash = { q1: 2, q3: 3, q4: 2, q5: 0, q6: 5 }
    let(:responses) { hash }
    context 'started' do
      let(:status) { :started }
      errors = ['is not included in the list']
      specify { expect(subject_errors[:q6]).to eq(errors) }
    end
  end

  context 'with a full set of responses' do
    hash = { q1: 0, q2: 1, q3: 0, q4: 1, q5: 0, q6: 0 }
    let(:responses) { hash }
    context 'requested' do
      let(:status) { :requested }
      specify { is_expected.not_to be_valid }
    end
    context 'started' do
      let(:status) { :started }
      specify { is_expected.to be_valid }
      it 'raises not ready errors on final score methods' do
        expect { subject.result }.to raise_error(ResponseNotReadyError)
        expect { subject.positive? }.to raise_error(ResponseNotReadyError)
      end
    end
    context 'finished' do
      let(:status) { :finished }
      specify { is_expected.to be_valid }
      specify { expect(subject.answers).to eq [0, 1, 0, 1, 0, 0] }
    end
  end

  context 'with responses not indicating ADHD' do
    hash = { q1: 0, q2: 1, q3: 0, q4: 1, q5: 0, q6: 0 }
    let(:responses) { hash }
    context 'finished' do
      let(:status) { :finished }
      specify { is_expected.not_to be_positive }
    end
  end

  context 'with responses indicating ADHD' do
    hash = { q1: 2, q2: 2, q3: 0, q4: 1, q5: 3, q6: 3 }
    let(:responses) { hash }
    context 'finished' do
      let(:status) { :finished }
      specify { is_expected.to be_positive }
      specify { expect(subject.result).to be_truthy }
    end
  end
end
