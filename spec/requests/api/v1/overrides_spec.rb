require 'rails_helper'

RSpec.describe 'Api::V1::Overrides', type: :request do
  let(:headers) { { 'Content-Type' => 'application/json' } }
  let(:feature_flag) { create(:feature_flag) }

  describe 'POST /api/v1/feature_flags/:feature_flag_id/overrides' do
    context 'with valid params' do
      it 'creates a user override' do
        params = {
          type: 'user',
          identifier: 'user1',
          enabled: true
        }

        post "/api/v1/feature_flags/#{feature_flag.id}/overrides",
             params: params,
             as: :json

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['type']).to eq('user')
        expect(json['identifier']).to eq('user1')
        expect(json['enabled']).to be true
      end

      it 'creates a group override' do
        params = {
          type: 'group',
          identifier: 'group1',
          enabled: true
        }

        post "/api/v1/feature_flags/#{feature_flag.id}/overrides",
             params: params,
             as: :json

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['type']).to eq('group')
      end

      it 'creates a region override' do
        params = {
          type: 'region',
          identifier: 'us-east',
          enabled: true
        }

        post "/api/v1/feature_flags/#{feature_flag.id}/overrides",
             params: params,
             as: :json

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['type']).to eq('region')
      end

      it 'updates existing override' do
        create(:user_override, feature_flag: feature_flag, user_id: 'user1', enabled: false)

        params = {
          type: 'user',
          identifier: 'user1',
          enabled: true
        }

        post "/api/v1/feature_flags/#{feature_flag.id}/overrides",
             params: params,
             as: :json

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['enabled']).to be true
      end
    end

    context 'with invalid params' do
      it 'returns error when type is invalid' do
        params = {
          type: 'invalid',
          identifier: 'user1',
          enabled: true
        }

        post "/api/v1/feature_flags/#{feature_flag.id}/overrides",
             params: params,
             as: :json

        expect(response).to have_http_status(:bad_request)
      end

      it 'returns error when identifier is missing' do
        params = {
          type: 'user',
          enabled: true
        }

        post "/api/v1/feature_flags/#{feature_flag.id}/overrides",
             params: params,
             as: :json

        expect(response).to have_http_status(:bad_request)
      end

      it 'returns error when enabled is missing' do
        params = {
          type: 'user',
          identifier: 'user1'
        }

        post "/api/v1/feature_flags/#{feature_flag.id}/overrides",
             params: params,
             as: :json

        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'DELETE /api/v1/feature_flags/:feature_flag_id/overrides' do
    it 'removes a user override' do
      create(:user_override, feature_flag: feature_flag, user_id: 'user1', enabled: true)

      delete "/api/v1/feature_flags/#{feature_flag.id}/overrides",
             params: { type: 'user', identifier: 'user1' },
             as: :json

      expect(response).to have_http_status(:no_content)
      expect(UserOverride.count).to eq(0)
    end

    it 'returns error when override does not exist' do
      delete "/api/v1/feature_flags/#{feature_flag.id}/overrides",
             params: { type: 'user', identifier: 'nonexistent' },
             as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end

