class PHQ9Evaluator
  attr_accessor :errors
  valid_keys = %i[q1 q2 q3 q4 q5 q6 q7 q8 q9 q10]
  def initialize(responses)
    @responses = responses
    valid_keys.each do |q|
      @errors[key] = []
    end
  end

  def valid?
    populate_errors
    return false unless valid_keys.sort == @responses.keys.sort
    valid_keys.each do |q|
      return false unless (@responses[q].is_a? Integer) &&
                          (@responses[q] >= 0) && (@responses[q] <= 3)
    end
    true
  end

  def score
    return @responses.values.reduce(:+) - @responses[:q10] if valid?
  end

  private

  def populate_errors
    valid_keys.each do |q|
      valid_key_errors(q).each do |e|
        @errors[q].push(e)
      end
    end
    @responses.keys do |key|
      @errors[key].push('invalid key') unless valid_keys.include? key
    end
  end

  def type_error(key)
    return 'type error' unless @responses[key].is_a? Integer
  end

  def range_error(key)
    return 'range error' unless (@responses[key] >= 0) &&
                                (@responses[key] <= 3)
  end

  def not_found_error(key)
    return 'response not found' unless @responses[key]
  end

  def valid_key_errors(key)
    errors = []
    errors.push(type_error(key))
    errors.push(range_error(key))
    errors.push(not_found_error(key))
    errors - [nil]
  end
end
