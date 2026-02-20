module FeatureFlags
  # Service for updating feature flags
  class UpdateService
    def initialize(feature_flag, params)
      @feature_flag = feature_flag
      @params = normalize_params(params)
    end

    def call
      if feature_flag.update(validated_params)
        { success: true, feature_flag: feature_flag }
      else
        { success: false, errors: feature_flag.errors.full_messages }
      end
    end

    private

    attr_reader :feature_flag, :params

    def normalize_params(params)
      return params if params.is_a?(Hash) && !params.respond_to?(:permit)
      params.to_h.with_indifferent_access
    rescue
      params.is_a?(Hash) ? params.with_indifferent_access : params
    end

    def validated_params
      update_params = {}
      update_params[:name] = params[:name] if params.key?(:name)
      update_params[:global_default_state] = params[:global_default_state] if params.key?(:global_default_state)
      update_params[:description] = params[:description] if params.key?(:description)
      update_params
    end
  end
end

