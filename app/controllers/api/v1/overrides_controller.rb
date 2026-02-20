module Api
  module V1
    class OverridesController < ApplicationController
      before_action :set_feature_flag

      # POST /api/v1/feature_flags/:feature_flag_id/overrides
      def create
        override_type = params[:type]&.to_sym
        identifier = params[:identifier]
        enabled = params[:enabled]

        validate_override_params!(override_type, identifier, enabled)

        service = FeatureFlags::OverrideService.new(
          @feature_flag,
          override_type,
          identifier,
          enabled
        )

        result = service.create_or_update

        if result[:success]
          render json: serialize_override(result[:override], override_type), status: :created
        else
          raise ValidationError.new(result[:errors])
        end
      end

      # DELETE /api/v1/feature_flags/:feature_flag_id/overrides
      def destroy
        override_type = params[:type]&.to_sym
        identifier = params[:identifier]

        validate_override_params!(override_type, identifier, nil)

        service = FeatureFlags::OverrideService.new(
          @feature_flag,
          override_type,
          identifier,
          nil
        )

        result = service.remove

        if result[:success]
          head :no_content
        else
          raise ValidationError.new(result[:errors])
        end
      end

      private

      def set_feature_flag
        feature_flag_id = params[:feature_flag_id] || params[:id]
        @feature_flag = FeatureFlag.find(feature_flag_id)
      rescue ActiveRecord::RecordNotFound
        feature_flag_id = params[:feature_flag_id] || params[:id]
        raise FeatureFlagNotFoundError.new(feature_flag_id)
      end

      def validate_override_params!(override_type, identifier, enabled)
        unless [:user, :group, :region].include?(override_type)
          raise ArgumentError, "Type must be one of: user, group, region"
        end

        if identifier.blank?
          raise ArgumentError, "Identifier is required"
        end

        if enabled.nil? && action_name == "create"
          raise ArgumentError, "Enabled is required"
        end
      end

      def serialize_override(override, type)
        identifier = case type
                     when :user
                       override.user_id
                     when :group
                       override.group_id
                     when :region
                       override.region
                     end

        {
          id: override.id,
          feature_flag_id: override.feature_flag_id,
          type: type.to_s,
          identifier: identifier,
          enabled: override.enabled,
          created_at: override.created_at,
          updated_at: override.updated_at
        }
      end
    end
  end
end

