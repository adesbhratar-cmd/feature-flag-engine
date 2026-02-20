# Concern for handling application errors consistently
# Provides centralized error handling for all API controllers
module ErrorHandler
  extend ActiveSupport::Concern

  included do
    # Global error handling
    # Custom errors use their to_json method for consistent formatting
    rescue_from ApplicationError, with: :handle_application_error
    
    # Rails exceptions use helper method for consistent JSON structure
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
    rescue_from ArgumentError, with: :handle_argument_error
  end

  private

  # Handles all custom ApplicationError subclasses
  # Uses the error's to_json method for consistent formatting
  def handle_application_error(exception)
    render json: exception.to_json, status: exception.status_code
  end

  # Handles ActiveRecord::RecordNotFound
  def handle_not_found(exception)
    render json: ApplicationError.error_json(
      type: :not_found,
      message: exception.message
    ), status: :not_found
  end

  # Handles ActiveRecord::RecordInvalid (Rails validation errors)
  def handle_validation_error(exception)
    render json: ApplicationError.error_json(
      type: :validation_error,
      message: exception.message,
      details: exception.record.errors.full_messages
    ), status: :unprocessable_entity
  end

  # Handles ArgumentError (invalid arguments)
  def handle_argument_error(exception)
    render json: ApplicationError.error_json(
      type: :argument_error,
      message: exception.message
    ), status: :bad_request
  end
end

