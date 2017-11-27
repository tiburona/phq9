require 'active_model'

# a class to validate responses to the PHQ-9
class ResponseValidator < ActiveModel::Validator
  def validate(record)
    required_validation(record)
    permitted_validation(record)
    other_validation(record)
  end

  def required_validation(record)
    required_responses = record.validation_schema[:required_responses]
    record.status == :submitted &&
      required_responses && required_responses.each do |key|
        populate_error(record, key, 'response not found') unless
        record.responses[key]
      end
  end

  def permitted_validation(record)
    permitted_responses = record.validation_schema[:permitted_responses]
    permitted_responses && record.responses.each_key do |key|
      populate_error(record, key, 'invalid key') unless
      permitted_responses.include? key
    end
  end

  def other_validation(record)
    response_validations = record.validation_schema[:response_validations]
    response_validations && response_validations.each do |key, validations|
      validations.each do |validation|
        validate_responses(record, key, validation)
      end
    end
  end

  def validate_responses(record, key, validation)
    populate_error(record, key, validation[:msg]) unless
    !record.responses[key] || error_exists(record, key) ||
    validation[:validation].call(record.responses[key])
  end

  def error_exists(record, key)
    !record.errors[key].empty?
  end

  def populate_error(record, key, message)
    record.errors[key] << message
  end
end
