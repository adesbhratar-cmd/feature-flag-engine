module FeatureFlags
  # Rule Engine for extensible feature flag evaluation
  # This allows for future rule types to be easily added
  class RuleEngine
    def initialize(feature_flag:, context: {})
      @feature_flag = feature_flag
      @context = context.with_indifferent_access
    end

    # Evaluates all applicable rules and returns the result
    def evaluate
      rules = build_rule_chain
      rules.find(&:applicable?)&.evaluate || default_state
    end

    private

    attr_reader :feature_flag, :context

    # Builds a chain of rules in order of precedence
    def build_rule_chain
      [
        UserOverrideRule.new(feature_flag: feature_flag, context: context),
        GroupOverrideRule.new(feature_flag: feature_flag, context: context),
        RegionOverrideRule.new(feature_flag: feature_flag, context: context),
        GlobalDefaultRule.new(feature_flag: feature_flag, context: context)
      ]
    end

    def default_state
      feature_flag.global_default_state
    end
  end

  # Base rule class for strategy pattern
  class BaseRule
    def initialize(feature_flag:, context: {})
      @feature_flag = feature_flag
      @context = context.with_indifferent_access
    end

    def applicable?
      raise NotImplementedError, "Subclasses must implement #applicable?"
    end

    def evaluate
      raise NotImplementedError, "Subclasses must implement #evaluate"
    end

    protected

    attr_reader :feature_flag, :context
  end

  # User-specific override rule
  class UserOverrideRule < BaseRule
    def applicable?
      user_id.present? && override.present?
    end

    def evaluate
      override.enabled
    end

    private

    def override
      @override ||= feature_flag.user_overrides.for_user(user_id).first
    end

    def user_id
      @user_id ||= context[:user_id]&.to_s&.downcase&.strip
    end
  end

  # Group-specific override rule
  class GroupOverrideRule < BaseRule
    def applicable?
      group_id.present? && override.present?
    end

    def evaluate
      override.enabled
    end

    private

    def override
      @override ||= feature_flag.group_overrides.for_group(group_id).first
    end

    def group_id
      @group_id ||= context[:group_id]&.to_s&.downcase&.strip
    end
  end

  # Region-specific override rule (Phase 2)
  class RegionOverrideRule < BaseRule
    def applicable?
      region.present? && override.present?
    end

    def evaluate
      override.enabled
    end

    private

    def override
      @override ||= feature_flag.region_overrides.for_region(region).first
    end

    def region
      @region ||= context[:region]&.to_s&.downcase&.strip
    end
  end

  # Global default rule (fallback)
  class GlobalDefaultRule < BaseRule
    def applicable?
      true # Always applicable as fallback
    end

    def evaluate
      feature_flag.global_default_state
    end
  end
end

