# Base error class for the application
class ApplicationError < StandardError
  attr_reader :type, :status_code

  def initialize(message, type: :application_error, status_code: 500)
    super(message)
    @type = type
    @status_code = status_code
  end

  # Converts error to JSON hash (not JSON string)
  # Used by ApplicationController to render consistent error responses
  def to_json
    {
      error: {
        type: type.to_s,
        message: message
      }
    }
  end

  # Helper method to build consistent error JSON structure
  # Used for Rails exceptions that don't inherit from ApplicationError
  def self.error_json(type:, message:, details: nil)
    json = {
      error: {
        type: type.to_s,
        message: message
      }
    }
    json[:error][:details] = details if details
    json
  end
end

