require_relative 'custom_validation_errors'
require 'active_model'

# a class to evaluate responses to the PHQ-9
class AlcoholScreeningEvaluator
  include ActiveModel::Validations
  attr_reader :status, :responses, :q1, :q2, :q3, :q4, :q5, :q6, :q7, :q8, :q9,
              :q10
  validate :check_for_empty_responses, if: :requested?
  validate :check_for_invalid_keys
  validates :q1, :q2, :q3, :q4, :q5, :q6, :q7, :q8, :q9, :q10,
            presence: { if: :finished? }
  validates :q1, :q2, :q3, :q4, :q5, :q6, :q7, :q8, :q9, :q10,
            inclusion: { in: 0..4, if: :finished? }
  validates :q1, :q2, :q3, :q4, :q5, :q6, :q7, :q8, :q9, :q10,
            inclusion: { in: [0, 1, 2, 3, 4, nil], if: :started? || :canceled? }

  ANSWER_KEYS = %i[q1 q2 q3 q4 q5 q6 q7 q8 q9 q10].freeze

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

  def positive?
    score >= 8
  end

  def abbr
    'AUDIT'
  end

  def disorder
    'Alcohol Use Disorder'
  end

  def max_score
    40
  end

  def auditc?; end

  def auditcpositive?
    q1 + q2 + q3 >= 3 && (q2 + q3 > 0)
  end

  def score
    raise_unless_finished_and_valid!
    return @responses[:q1] + @responses[:q2] unless !auditc? || auditcpositive?
    @responses.select { |k, _v| ANSWER_KEYS.include? k }
              .values
              .reduce(:+)
  end

  def answers
    raise_unless_finished_and_valid!
    return [@responses[:q1], @responses[:q2]] unless !auditc? || auditcpositive?
    @responses.select { |k, _v| ANSWER_KEYS.include? k }
              .values
  end

  def acuity
    return 'none' if score < 8
    return 'hazardous/harmful alcohol consumption' if score < 16
    return 'high level of alcohol problems' if score < 20
    'probable alcohol dependence'
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

  def raise_unless_valid_keys!(keys)
    keys.each do |key|
      raise InvalidResponseError, 'invalid key' unless [0, 1, 2, 3]
                                                       .include? @responses[key]
    end
    raise InvalidResponseError, 'invalid responses' unless valid?
  end
end
