require 'rails_helper'

RSpec.describe FeatureFlags::CreateService do
  describe '#call' do
    context 'with valid params' do
      it 'creates a feature flag' do
        params = { name: 'new_feature', global_default_state: true, description: 'A new feature' }
        service = described_class.new(params)
        result = service.call

        expect(result[:success]).to be true
        expect(result[:feature_flag]).to be_persisted
        expect(result[:feature_flag].name).to eq('new_feature')
        expect(result[:feature_flag].global_default_state).to be true
      end

      it 'defaults global_default_state to false when not provided' do
        params = { name: 'new_feature' }
        service = described_class.new(params)
        result = service.call

        expect(result[:success]).to be true
        expect(result[:feature_flag].global_default_state).to be false
      end
    end

    context 'with invalid params' do
      it 'returns errors when name is missing' do
        params = { global_default_state: true }
        service = described_class.new(params)
        result = service.call

        expect(result[:success]).to be false
        expect(result[:errors]).to be_present
      end

      it 'returns errors when name is duplicate' do
        create(:feature_flag, name: 'existing_feature')
        params = { name: 'existing_feature' }
        service = described_class.new(params)
        result = service.call

        expect(result[:success]).to be false
        expect(result[:errors]).to be_present
      end

      it 'handles case-insensitive duplicate names' do
        create(:feature_flag, name: 'existing_feature')
        params = { name: 'EXISTING_FEATURE' }
        service = described_class.new(params)
        result = service.call

        expect(result[:success]).to be false
        expect(result[:errors]).to be_present
      end
    end
  end
end

