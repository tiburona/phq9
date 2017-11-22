require 'active_model'

# a class to validate responses to the PHQ-9
class ResponseValidator < ActiveModel::Validator
  def validate(record)
    required_responses_validation(record)
    permitted_responses_validation(record)
    validate_responses(record)
  end

  def required_responses_validation(record)
    required_responses = record.validation_schema[:required_responses]
    required_responses && required_responses.each do |key|
      populate_error(record, key, 'response not found') unless
      record.responses[key]
    end
  end

  def permitted_responses_validation(record)
    permitted_responses = record.validation_schema[:permitted_responses]
    permitted_responses && record.responses.each_key do |key|
      populate_error(record, key, 'invalid key') unless
      permitted_responses.include? key
    end
  end

  def validate_responses(record)
    response_validations = record.validation_schema[:response_validations]
    responses = record.responses
    response_validations && response_validations.each do |key, validations|
      validations.each do |v|
        populate_error(record, key, v[:msg]) unless
        !responses[key] || v[:validation].call(responses[key])
      end
    end
  end

  def populate_error(record, key, message)
    record.errors[key] << message
  end
end
