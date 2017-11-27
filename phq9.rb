require_relative 'response_validator'

# a class to evaluate responses to the PHQ-9
class PHQ9Evaluator
  include ActiveModel::Validations
  attr_reader :responses
  attr_reader :status
  validates_with ResponseValidator
  # class should init with pending or submitting
  # pending or submitted
  # validation different depending on status
  # every method which calcs a score should throw error_exists
  # raise if not valid for final score methods

  def initialize(responses, status)
    @responses = responses
    @status = status
  end

  def validation_schema
    schema = { required_responses: required_keys,
               permitted_responses: permitted_keys,
               response_validations: {} }
    permitted_keys.each do |key|
      schema[:response_validations][key] = response_validations
    end
    schema
  end

  def permitted_keys
    %i[q1 q2 q3 q4 q5 q6 q7 q8 q9 q10]
  end

  def required_keys
    %i[q1 q2 q3 q4 q5 q6 q7 q8 q9 q10]
  end

  def response_validations
    [
      { name: :type_validation, validation: proc { |ans| ans.is_a? Integer },
        msg: 'type error' },
      { name: :range_validation,
        validation: proc { |ans| ans >= 0 && ans <= 3 },
        msg: 'range error' }
    ]
  end

  # why are this method and the next "self.method" in the original model?
  # does that do anything different?
  def abbr
    'PHQ-9'
  end

  # formerly abbr_meaning
  def disorder
    'Depression'
  end

  def max_score
    27
  end

  def score_phq9
    raise 'response is still pending' unless status == :submitted
    responses.values.reduce(:+) - responses[:q10]
  end

  # note: AFAICT this is only being used in a haml screenings page
  # is this something we're currently using ?
  def score_phq2
    raise 'response is still pending' unless status == :submitted
    responses[:q1] + responses[:q2]
  end

  def score
    return score_phq9 unless phq2? && !enforce_phq9?
    score_phq2
  end

  def acuity
    return 'none' if score_phq9 < 5
    return 'mild' if score_phq9 < 10
    return 'moderate' if score_phq9 < 15
    return 'moderately severe' if score_phq9 < 20
    'severe'
  end

  def suic_ideation_score
    responses[:q9]
  end

  # this is a method that is not defined in screenings.rb
  # since self.ph2? has to be true to ever score a phq2,
  # I'm not sure any of the phq2 functionality is actually
  # used in the project
  def phq2?; end

  def phq2_positive?
    responses[:q1] + responses[:q2] >= 3
  end

  def somewhat_depressed?
    responses[:q1] > 1 || responses[:q2] > 1
  end

  def pretty_depressed?
    (%i[q1 q2 q3 q4 q5 q6 q7 q8]
      .map { |key| responses[key] }
      .count { |key| key == 2 || key == 3 } +
      (responses[:q9] > 0 ? 1 : 0)) >= 5
  end

  def impact?
    responses[:q10] > 0
  end

  def result
    somewhat_depressed? && pretty_depressed? && impact? unless
      phq2? && !phq2_positive
  end

  def positive?
    score >= 5
  end

  def eligible_for_spring_assessment?
    score >= 10
  end

  def severity
    return '(minimal)' if score < 5
    return '(mild)' if score < 10
    return '(moderate)' if score < 15
    return '(moderately severe)' if score < 20
    '(severe)'
  end

  def answers
    unless phq2? && !phq2positive?
      return %i[q1 q2 q3 q4 q5 q6 q7 q8 q9 q10].map { |q| responses[q] }
    end
    %i[q1 q2].map { |q| responses[q] }
  end
end
