require 'rails_helper'

RSpec.describe FeatureFlags::UpdateService do
  let(:feature_flag) { create(:feature_flag, name: 'old_name', global_default_state: false) }

  describe '#call' do
    context 'with valid params' do
      it 'updates feature flag name' do
        params = { name: 'new_name' }
        service = described_class.new(feature_flag, params)
        result = service.call

        expect(result[:success]).to be true
        expect(result[:feature_flag].name).to eq('new_name')
      end

      it 'updates global_default_state' do
        params = { global_default_state: true }
        service = described_class.new(feature_flag, params)
        result = service.call

        expect(result[:success]).to be true
        expect(result[:feature_flag].global_default_state).to be true
      end

      it 'updates description' do
        params = { description: 'New description' }
        service = described_class.new(feature_flag, params)
        result = service.call

        expect(result[:success]).to be true
        expect(result[:feature_flag].description).to eq('New description')
      end

      it 'only updates provided params' do
        original_name = feature_flag.name
        params = { global_default_state: true }
        service = described_class.new(feature_flag, params)
        result = service.call

        expect(result[:success]).to be true
        expect(result[:feature_flag].name).to eq(original_name)
        expect(result[:feature_flag].global_default_state).to be true
      end
    end

    context 'with invalid params' do
      it 'returns errors when name is duplicate' do
        create(:feature_flag, name: 'existing_name')
        params = { name: 'existing_name' }
        service = described_class.new(feature_flag, params)
        result = service.call

        expect(result[:success]).to be false
        expect(result[:errors]).to be_present
      end
    end
  end
end

