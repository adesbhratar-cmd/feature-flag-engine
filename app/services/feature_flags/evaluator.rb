module FeatureFlags
  # Main service for evaluating feature flag state
  # Implements the evaluation precedence: User > Group > Region > Global Default
  class Evaluator
    CACHE_PREFIX = "feature_flag_evaluation".freeze
    CACHE_TTL = 5.minutes

    def initialize(feature_flag:, context: {})
      @feature_flag = feature_flag
      @context = context.with_indifferent_access
    end

    # Evaluates the feature flag state based on context
    # Returns boolean indicating if feature is enabled
    def evaluate
      cached_result || evaluate_and_cache
    end

    # Returns the evaluation result with metadata about which override was used
    def evaluate_with_metadata
      result = evaluate_uncached
      {
        enabled: result[:enabled],
        source: result[:source],
        feature_flag_name: @feature_flag.name
      }
    end

    private

    attr_reader :feature_flag, :context

    def cached_result
      return nil unless cache_enabled?

      cache_key = build_cache_key
      Rails.cache.read(cache_key)
    end

    def evaluate_and_cache
      result = evaluate_uncached
      
      if cache_enabled?
        cache_key = build_cache_key
        Rails.cache.write(cache_key, result[:enabled], expires_in: CACHE_TTL)
      end
      
      result[:enabled]
    end

    def evaluate_uncached
      # Evaluation precedence: User > Group > Region > Global Default
      if user_override_exists?
        { enabled: user_override.enabled, source: :user }
      elsif group_override_exists?
        { enabled: group_override.enabled, source: :group }
      elsif region_override_exists?
        { enabled: region_override.enabled, source: :region }
      else
        { enabled: feature_flag.global_default_state, source: :global }
      end
    end

    def user_override_exists?
      user_id.present? && user_override.present?
    end

    def group_override_exists?
      group_id.present? && group_override.present?
    end

    def region_override_exists?
      region.present? && region_override.present?
    end

    def user_override
      @user_override ||= feature_flag.user_overrides
                                     .for_user(user_id)
                                     .first if user_id.present?
    end

    def group_override
      @group_override ||= feature_flag.group_overrides
                                       .for_group(group_id)
                                       .first if group_id.present?
    end

    def region_override
      @region_override ||= feature_flag.region_overrides
                                       .for_region(region)
                                       .first if region.present?
    end

    def user_id
      @user_id ||= context[:user_id]&.to_s&.downcase&.strip
    end

    def group_id
      @group_id ||= context[:group_id]&.to_s&.downcase&.strip
    end

    def region
      @region ||= context[:region]&.to_s&.downcase&.strip
    end

    def build_cache_key
      parts = [
        CACHE_PREFIX,
        feature_flag.id,
        user_id,
        group_id,
        region
      ].compact
      parts.join(":")
    end

    def cache_enabled?
      Rails.cache.respond_to?(:write)
    end
  end
end

