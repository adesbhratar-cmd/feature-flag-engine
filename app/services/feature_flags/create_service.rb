module FeatureFlags
  # Service for creating feature flags
  class CreateService
    def initialize(params)
      @params = normalize_params(params)
    end

    def call
      feature_flag = FeatureFlag.new(validated_params)
      
      if feature_flag.save
        { success: true, feature_flag: feature_flag }
      else
        { success: false, errors: feature_flag.errors.full_messages }
      end
    end

    private

    attr_reader :params

    def normalize_params(params)
      return params if params.is_a?(Hash) && !params.respond_to?(:permit)
      params.to_h.with_indifferent_access
    rescue
      params.is_a?(Hash) ? params.with_indifferent_access : params
    end

    def validated_params
      {
        name: params[:name],
        global_default_state: params.fetch(:global_default_state, false),
        description: params[:description]
      }
    end
  end
end

