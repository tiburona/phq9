require 'active_model'

# a class to validate responses to the PHQ-9
class ResponseValidator < ActiveModel::Validator
  def validate(record)
    validate_responses(record)
    validate_keys(record)
  end

  def validate_responses(record)
    %i[q1 q2 q3 q4 q5 q6 q7 q8 q9 q10].each do |key|
      answer = record.responses[key]
      populate_error(record, key, 'not answered') unless answer
      populate_error(record, key, 'wrong type') unless !answer ||
                                                       type_valid?(answer)
      populate_error(record, key, 'out of range') unless !answer ||
                                                         range_valid?(answer)
    end
  end

  def populate_error(record, key, message)
    record.errors[key] << message
  end

  def validate_keys(record)
    record.responses.each_key do |key|
      populate_error(record, key, 'invalid key') unless
      %i[q1 q2 q3 q4 q5 q6 q7 q8 q9 q10].include? key
    end
  end

  def range_valid?(ans)
    ans && (ans >= 0) && (ans <= 3)
  end

  def type_valid?(ans)
    ans.is_a? Integer if ans
  end
end

# a class to evaluate responses to the PHQ-9
class PHQ9Evaluator
  include ActiveModel::Validations
  attr_reader :responses
  validates_with ResponseValidator

  def initialize(responses)
    @responses = responses
  end

  def score
    return @responses.values.reduce(:+) - @responses[:q10] if valid?
  end

  def acuity
    return 'none' if score < 5
    return 'mild' if score < 10
    return 'moderate' if score < 15
    return 'moderately severe' if score < 20
    'severe'
  end

  def suic_ideation_score
    responses[:q9]
  end

  def phq2_positive?
    responses[:q1] + responses[:q2] >= 3
  end

  def step1?
    responses[:q1] > 1 || responses[:q2] > 1
  end
end
