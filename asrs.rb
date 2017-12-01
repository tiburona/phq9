require_relative 'custom_validation_errors'
require 'active_model'

# a class to evaluate responses to the PHQ-9
class ASRSEvaluator
  include ActiveModel::Validations
  attr_reader :status, :responses, :q1, :q2, :q3, :q4, :q5, :q6
  validate :check_for_empty_responses, if: :requested?
  validate :check_for_invalid_keys
  validates :q1, :q2, :q3, :q4, :q5, :q6, presence: { if: :finished? }
  validates :q1, :q2, :q3, :q4, :q5, :q6,
            inclusion: { in: 0..4, if: :finished? }
  validates :q1, :q2, :q3, :q4, :q5, :q6,
            inclusion: { in: [0, 1, 2, 3, 4, nil], if: :started? || :canceled? }

  ANSWER_KEYS = %i[q1 q2 q3 q4 q5 q6].freeze

  def initialize(responses, status)
    @responses = responses.select { |k, _v| ANSWER_KEYS.include? k }
    @invalid_keys = responses.reject { |k, _v| ANSWER_KEYS.include? k }
    @responses.each do |key, val|
      var_name = "@#{key}"
      instance_variable_set(var_name, val)
    end
    @status = status
  end

  def requested?
    @status == :requested
  end

  def started?
    @status == :started
  end

  def finished?
    @status == :finished
  end

  def canceled?
    @status == :canceled
  end

  def abbr
    'ASRS'
  end

  def disorder
    'Adult ADHD'
  end

  def result
    raise_unless_finished_and_valid!
    ([q1, q2, q3].count { |ans| ans > 1 } +
     [q5, q5, q6].count { |ans| ans > 2 }) >= 4
  end

  def positive?
    raise_unless_finished_and_valid!
    result
  end

  def answers
    raise_unless_finished_and_valid!
    @responses.select { |k, _v| ANSWER_KEYS.include? k }
              .values
  end

  private

  def check_for_empty_responses
    @responses.each_key { |k| @errors.messages[k] = ['responses not empty'] }
  end

  def check_for_invalid_keys
    @invalid_keys.each_key do |k|
      @errors.messages[k] = ['invalid key']
    end
  end

  def raise_unless_finished_and_valid!
    raise InvalidResponseError unless valid?
    raise ResponseNotReadyError unless status == :finished
  end
end
