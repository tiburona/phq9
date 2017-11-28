require 'active_model'

# a class to validate responses to the PHQ-9
class ResponseValidator < ActiveModel::Validator
  def validate(record)
    permitted_keys = %i[q1 q2 q3 q4 q5 q6 q7 q8 q9 q10]
    record.responses.each_key do |key|
      record.errors[key] << 'forbidden key' unless permitted_keys.include?(key)
    end
  end
end
