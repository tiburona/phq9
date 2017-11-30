require_relative 'response_validator'

# a class to evaluate responses to the PHQ-9
class PHQ9Evaluator
  include ActiveModel::Validations
  attr_reader :status, :responses, :q1, :q2, :q3, :q4, :q5, :q6, :q7, :q8, :q9,
              :q10
  validate :check_for_invalid_keys
  validates :q1, :q2, :q3, :q4, :q5, :q6, :q7, :q8, :q9, :q10,
            presence: { unless: :pending? }
  validates :q1, :q2, :q3, :q4, :q5, :q6, :q7, :q8, :q9, :q10,
            inclusion: { in: 0..3, unless: :pending? }
  validates :q1, :q2, :q3, :q4, :q5, :q6, :q7, :q8, :q9, :q10,
            inclusion: { in: [0, 1, 2, 3, nil], if: :pending? }

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

  def pending?
    @status == :pending
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
    raise_unless_submitted_and_valid!
    @responses.select { |k, _v| %i[q1 q2 q3 q4 q5 q6 q7 q8 q9].include? k }
              .values
              .reduce(:+)
  end

  # note: AFAICT this is only being used in a haml screenings page
  # is this something we're currently using ?
  def score_phq2
    raise_unless_submitted_and_valid!
    responses[:q1] + responses[:q2]
  end

  def score
    raise_unless_submitted_and_valid!
    return score_phq9 unless phq2? && !enforce_phq9?
    score_phq2
  end

  def acuity
    raise_unless_submitted_and_valid!
    return 'none' if score_phq9 < 5
    return 'mild' if score_phq9 < 10
    return 'moderate' if score_phq9 < 15
    return 'moderately severe' if score_phq9 < 20
    'severe'
  end

  def suic_ideation_score
    raise_unless_valid_keys!([:q9])
    responses[:q9]
  end

  # this is a method that is not defined in screenings.rb
  # since self.ph2? has to be true to ever score a phq2,
  # I'm not sure any of the phq2 functionality is actually
  # used in the project
  def phq2?; end

  def phq2_positive?
    raise_unless_submitted_and_valid!
    responses[:q1] + responses[:q2] >= 3
  end

  def somewhat_depressed?
    raise_unless_submitted_and_valid!
    responses[:q1] > 1 || responses[:q2] > 1
  end

  def pretty_depressed?
    raise_unless_submitted_and_valid!
    (%i[q1 q2 q3 q4 q5 q6 q7 q8 q9]
      .map { |key| responses[key] }
      .count { |key| key == 2 || key == 3 } +
      (responses[:q9] > 0 ? 1 : 0)) >= 5
  end

  def impacted?
    raise_unless_submitted_and_valid!
    responses[:q10] > 0
  end

  def result
    raise_unless_submitted_and_valid!
    somewhat_depressed? && pretty_depressed? && impacted? unless
      phq2? && !phq2_positive
  end

  def positive?
    score >= 5
  end

  def eligible_for_spring_assessment?
    score >= 10
  end

  def severity
    raise_unless_submitted_and_valid!
    return '(minimal)' if score < 5
    return '(mild)' if score < 10
    return '(moderate)' if score < 15
    return '(moderately severe)' if score < 20
    '(severe)'
  end

  def answers
    raise_unless_submitted_and_valid!
    return ANSWER_KEYS.map { |q| responses[q] } unless phq2? && !phq2positive?
    %i[q1 q2].map { |q| responses[q] }
  end

  private

  def check_for_invalid_keys
    @invalid_keys.each_key do |k|
      @errors.messages[k] = ['invalid key']
    end
  end

  def raise_unless_submitted_and_valid!
    raise InvalidResponseError unless valid?
    raise ResponseNotReadyError unless status == :submitted
  end

  def raise_unless_valid_keys!(keys)
    keys.each do |key|
      raise InvalidResponseError, 'invalid key' unless [0, 1, 2, 3]
                                                       .include? @responses[key]
    end
    raise InvalidResponseError, 'invalid responses' unless valid?
  end
end
