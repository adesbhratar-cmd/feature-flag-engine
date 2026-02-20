module FeatureFlags
  # Service for managing overrides (user, group, region)
  class OverrideService
    OVERRIDE_TYPES = {
      user: UserOverride,
      group: GroupOverride,
      region: RegionOverride
    }.freeze

    def initialize(feature_flag, override_type, identifier, enabled)
      @feature_flag = feature_flag
      @override_type = override_type.to_sym
      @identifier = identifier
      @enabled = enabled
    end

    def create_or_update
      validate_override_type!
      
      override = find_or_initialize_override
      override.enabled = enabled
      
      if override.save
        invalidate_cache
        { success: true, override: override }
      else
        { success: false, errors: override.errors.full_messages }
      end
    end

    def remove
      validate_override_type!
      
      override = find_override
      return { success: false, errors: ["Override not found"] } unless override

      if override.destroy
        invalidate_cache
        { success: true }
      else
        { success: false, errors: ["Failed to remove override"] }
      end
    end

    private

    attr_reader :feature_flag, :override_type, :identifier, :enabled

    def validate_override_type!
      unless OVERRIDE_TYPES.key?(override_type)
        raise ArgumentError, "Invalid override type: #{override_type}. Must be one of: #{OVERRIDE_TYPES.keys.join(', ')}"
      end
    end

    def override_class
      OVERRIDE_TYPES[override_type]
    end

    def find_or_initialize_override
      scope = feature_flag.send("#{override_type}_overrides")
      normalized_id = normalize_identifier(identifier)
      
      case override_type
      when :user
        scope.find_or_initialize_by(user_id: normalized_id)
      when :group
        scope.find_or_initialize_by(group_id: normalized_id)
      when :region
        scope.find_or_initialize_by(region: normalized_id)
      end
    end

    def find_override
      scope = feature_flag.send("#{override_type}_overrides")
      normalized_id = normalize_identifier(identifier)
      
      case override_type
      when :user
        scope.for_user(normalized_id).first
      when :group
        scope.for_group(normalized_id).first
      when :region
        scope.for_region(normalized_id).first
      end
    end

    def normalize_identifier(id)
      id&.to_s&.downcase&.strip
    end

    def invalidate_cache
      # Invalidate all cache entries for this feature flag
      # In a production system, you might want more granular cache invalidation
      Rails.cache.delete_matched("#{Evaluator::CACHE_PREFIX}:#{feature_flag.id}:*") if Rails.cache.respond_to?(:delete_matched)
    end
  end
end

