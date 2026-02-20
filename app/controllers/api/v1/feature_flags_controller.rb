module Api
  module V1
    class FeatureFlagsController < ApplicationController
      before_action :set_feature_flag, only: [:show, :update, :destroy, :evaluate, :overrides]

      # GET /api/v1/feature_flags
      def index
        feature_flags = FeatureFlag.all.order(:name)
        render json: feature_flags.map { |ff| serialize_feature_flag(ff) }
      end

      # GET /api/v1/feature_flags/:id
      def show
        render json: serialize_feature_flag(@feature_flag)
      end

      # POST /api/v1/feature_flags
      def create
        service = FeatureFlags::CreateService.new(feature_flag_params)
        result = service.call

        if result[:success]
          render json: serialize_feature_flag(result[:feature_flag]), status: :created
        else
          raise ValidationError.new(result[:errors])
        end
      end

      # PATCH/PUT /api/v1/feature_flags/:id
      def update
        service = FeatureFlags::UpdateService.new(@feature_flag, feature_flag_params)
        result = service.call

        if result[:success]
          render json: serialize_feature_flag(result[:feature_flag])
        else
          raise ValidationError.new(result[:errors])
        end
      end

      # DELETE /api/v1/feature_flags/:id
      def destroy
        if @feature_flag.destroy
          head :no_content
        else
          raise FeatureFlagError.new("Failed to delete feature flag")
        end
      end

      # POST /api/v1/feature_flags/:id/evaluate
      def evaluate
        evaluator = FeatureFlags::Evaluator.new(
          feature_flag: @feature_flag,
          context: evaluation_context
        )

        if params[:metadata] == "true"
          result = evaluator.evaluate_with_metadata
          render json: result
        else
          enabled = evaluator.evaluate
          render json: { enabled: enabled, feature_flag_name: @feature_flag.name }
        end
      end

      # GET /api/v1/feature_flags/:id/overrides
      def overrides
        overrides_data = {
          user_overrides: @feature_flag.user_overrides.map { |o| serialize_override(o, :user) },
          group_overrides: @feature_flag.group_overrides.map { |o| serialize_override(o, :group) },
          region_overrides: @feature_flag.region_overrides.map { |o| serialize_override(o, :region) }
        }
        render json: overrides_data
      end

      private

      def set_feature_flag
        @feature_flag = FeatureFlag.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        raise FeatureFlagNotFoundError.new(params[:id])
      end

      def feature_flag_params
        params.require(:feature_flag).permit(:name, :global_default_state, :description)
      end

      def evaluation_context
        {
          user_id: params[:user_id],
          group_id: params[:group_id],
          region: params[:region]
        }.compact
      end

      def serialize_feature_flag(feature_flag)
        {
          id: feature_flag.id,
          name: feature_flag.name,
          global_default_state: feature_flag.global_default_state,
          description: feature_flag.description,
          created_at: feature_flag.created_at,
          updated_at: feature_flag.updated_at
        }
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

