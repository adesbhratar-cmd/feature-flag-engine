# Error for feature flag related issues
class FeatureFlagError < ApplicationError
  def initialize(message, status_code: 400)
    super(message, type: :feature_flag_error, status_code: status_code)
  end
end

# Error when feature flag is not found
class FeatureFlagNotFoundError < FeatureFlagError
  def initialize(feature_name)
    super("Feature flag '#{feature_name}' not found", status_code: 404)
  end
end

# Error for validation failures
class ValidationError < ApplicationError
  def initialize(errors)
    message = errors.is_a?(Array) ? errors.join(", ") : errors.to_s
    super(message, type: :validation_error, status_code: 422)
    @errors = errors.is_a?(Array) ? errors : [errors]
  end

  def to_json
    {
      error: {
        type: type.to_s,
        message: message,
        details: @errors
      }
    }
  end
end

