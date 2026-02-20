require 'rails_helper'

RSpec.describe 'Api::V1::FeatureFlags', type: :request do
  let(:headers) { { 'Content-Type' => 'application/json' } }

  describe 'GET /api/v1/feature_flags' do
    it 'returns all feature flags' do
      feature_flag1 = create(:feature_flag, name: 'feature1')
      feature_flag2 = create(:feature_flag, name: 'feature2')

      get '/api/v1/feature_flags', headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
      expect(json.map { |ff| ff['name'] }).to contain_exactly('feature1', 'feature2')
    end

    it 'returns empty array when no feature flags exist' do
      get '/api/v1/feature_flags', headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to eq([])
    end
  end

  describe 'GET /api/v1/feature_flags/:id' do
    let(:feature_flag) { create(:feature_flag, name: 'test_feature', global_default_state: true) }

    it 'returns a specific feature flag' do
      get "/api/v1/feature_flags/#{feature_flag.id}", headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['name']).to eq('test_feature')
      expect(json['global_default_state']).to be true
    end

    it 'returns 404 when feature flag does not exist' do
      get '/api/v1/feature_flags/99999', headers: headers

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['error']).to be_present
    end
  end

  describe 'POST /api/v1/feature_flags' do
    context 'with valid params' do
      it 'creates a new feature flag' do
        params = {
          feature_flag: {
            name: 'new_feature',
            global_default_state: true,
            description: 'A new feature'
          }
        }

        post '/api/v1/feature_flags', params: params, as: :json

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['name']).to eq('new_feature')
        expect(json['global_default_state']).to be true
        expect(FeatureFlag.count).to eq(1)
      end
    end

    context 'with invalid params' do
      it 'returns validation errors when name is missing' do
        params = {
          feature_flag: {
            global_default_state: true
          }
        }

        post '/api/v1/feature_flags', params: params, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to be_present
      end

      it 'returns validation errors when name is duplicate' do
        create(:feature_flag, name: 'existing_feature')
        params = {
          feature_flag: {
            name: 'existing_feature'
          }
        }

        post '/api/v1/feature_flags', params: params, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /api/v1/feature_flags/:id' do
    let(:feature_flag) { create(:feature_flag, name: 'old_name', global_default_state: false) }

    it 'updates a feature flag' do
      params = {
        feature_flag: {
          name: 'new_name',
          global_default_state: true
        }
      }

      patch "/api/v1/feature_flags/#{feature_flag.id}", params: params, as: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['name']).to eq('new_name')
      expect(json['global_default_state']).to be true
    end
  end

  describe 'DELETE /api/v1/feature_flags/:id' do
    let(:feature_flag) { create(:feature_flag) }

    it 'deletes a feature flag' do
      delete "/api/v1/feature_flags/#{feature_flag.id}", headers: headers

      expect(response).to have_http_status(:no_content)
      expect(FeatureFlag.count).to eq(0)
    end
  end

  describe 'POST /api/v1/feature_flags/:id/evaluate' do
    let(:feature_flag) { create(:feature_flag, global_default_state: false) }

    it 'evaluates feature flag with no context' do
      post "/api/v1/feature_flags/#{feature_flag.id}/evaluate", headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['enabled']).to be false
      expect(json['feature_flag_name']).to eq(feature_flag.name)
    end

    it 'evaluates feature flag with user context' do
      create(:user_override, feature_flag: feature_flag, user_id: 'user1', enabled: true)

      post "/api/v1/feature_flags/#{feature_flag.id}/evaluate",
           params: { user_id: 'user1' },
           as: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['enabled']).to be true
    end

    it 'returns metadata when requested' do
      post "/api/v1/feature_flags/#{feature_flag.id}/evaluate?metadata=true",
           params: {},
           as: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key('enabled')
      expect(json).to have_key('source')
      expect(json).to have_key('feature_flag_name')
    end

    it 'evaluates with correct precedence' do
      create(:region_override, feature_flag: feature_flag, region: 'us-east', enabled: true)
      create(:group_override, feature_flag: feature_flag, group_id: 'group1', enabled: false)
      create(:user_override, feature_flag: feature_flag, user_id: 'user1', enabled: true)

      post "/api/v1/feature_flags/#{feature_flag.id}/evaluate",
           params: { user_id: 'user1', group_id: 'group1', region: 'us-east' },
           as: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['enabled']).to be true # User override should win
    end
  end

  describe 'GET /api/v1/feature_flags/:id/overrides' do
    let(:feature_flag) { create(:feature_flag) }

    it 'returns all overrides for a feature flag' do
      user_override = create(:user_override, feature_flag: feature_flag, user_id: 'user1')
      group_override = create(:group_override, feature_flag: feature_flag, group_id: 'group1')
      region_override = create(:region_override, feature_flag: feature_flag, region: 'us-east')

      get "/api/v1/feature_flags/#{feature_flag.id}/overrides", headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['user_overrides'].length).to eq(1)
      expect(json['group_overrides'].length).to eq(1)
      expect(json['region_overrides'].length).to eq(1)
    end

    it 'returns empty arrays when no overrides exist' do
      get "/api/v1/feature_flags/#{feature_flag.id}/overrides", headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['user_overrides']).to eq([])
      expect(json['group_overrides']).to eq([])
      expect(json['region_overrides']).to eq([])
    end
  end

  describe 'error handling' do
    it 'handles invalid feature flag ID in evaluate' do
      post '/api/v1/feature_flags/99999/evaluate', as: :json

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['error']).to be_present
    end

    it 'handles invalid feature flag ID in update' do
      patch '/api/v1/feature_flags/99999',
            params: { feature_flag: { name: 'new_name' } },
            as: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'handles invalid feature flag ID in delete' do
      delete '/api/v1/feature_flags/99999', as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end

