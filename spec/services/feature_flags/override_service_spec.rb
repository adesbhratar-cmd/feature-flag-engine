require 'rails_helper'

RSpec.describe FeatureFlags::OverrideService do
  let(:feature_flag) { create(:feature_flag) }

  describe '#create_or_update' do
    context 'with user override' do
      it 'creates a new user override' do
        service = described_class.new(feature_flag, :user, 'user1', true)
        result = service.create_or_update

        expect(result[:success]).to be true
        expect(result[:override]).to be_persisted
        expect(result[:override].user_id).to eq('user1')
        expect(result[:override].enabled).to be true
      end

      it 'updates existing user override' do
        create(:user_override, feature_flag: feature_flag, user_id: 'user1', enabled: false)
        service = described_class.new(feature_flag, :user, 'user1', true)
        result = service.create_or_update

        expect(result[:success]).to be true
        expect(result[:override].enabled).to be true
      end
    end

    context 'with group override' do
      it 'creates a new group override' do
        service = described_class.new(feature_flag, :group, 'group1', true)
        result = service.create_or_update

        expect(result[:success]).to be true
        expect(result[:override].group_id).to eq('group1')
        expect(result[:override].enabled).to be true
      end
    end

    context 'with region override' do
      it 'creates a new region override' do
        service = described_class.new(feature_flag, :region, 'us-east', true)
        result = service.create_or_update

        expect(result[:success]).to be true
        expect(result[:override].region).to eq('us-east')
        expect(result[:override].enabled).to be true
      end
    end

    context 'with invalid override type' do
      it 'raises ArgumentError' do
        service = described_class.new(feature_flag, :invalid, 'id', true)
        expect { service.create_or_update }.to raise_error(ArgumentError)
      end
    end

    context 'edge cases' do
      it 'handles case-insensitive identifiers' do
        create(:user_override, feature_flag: feature_flag, user_id: 'user1', enabled: false)
        # The service normalizes identifiers, so 'USER1' becomes 'user1' and matches
        service = described_class.new(feature_flag, :user, 'USER1', true)
        result = service.create_or_update

        expect(result[:success]).to be true
        expect(result[:override].enabled).to be true
        expect(result[:override].user_id).to eq('user1')
      end

      it 'handles whitespace in identifiers' do
        service = described_class.new(feature_flag, :user, '  user1  ', true)
        result = service.create_or_update

        expect(result[:success]).to be true
        expect(result[:override].user_id).to eq('user1')
      end
    end
  end

  describe '#remove' do
    context 'with existing override' do
      it 'removes user override' do
        create(:user_override, feature_flag: feature_flag, user_id: 'user1', enabled: true)
        service = described_class.new(feature_flag, :user, 'user1', nil)
        result = service.remove

        expect(result[:success]).to be true
        expect(UserOverride.where(user_id: 'user1').count).to eq(0)
      end

      it 'removes group override' do
        create(:group_override, feature_flag: feature_flag, group_id: 'group1', enabled: true)
        service = described_class.new(feature_flag, :group, 'group1', nil)
        result = service.remove

        expect(result[:success]).to be true
        expect(GroupOverride.where(group_id: 'group1').count).to eq(0)
      end

      it 'removes region override' do
        create(:region_override, feature_flag: feature_flag, region: 'us-east', enabled: true)
        service = described_class.new(feature_flag, :region, 'us-east', nil)
        result = service.remove

        expect(result[:success]).to be true
        expect(RegionOverride.where(region: 'us-east').count).to eq(0)
      end
    end

    context 'with non-existent override' do
      it 'returns error' do
        service = described_class.new(feature_flag, :user, 'nonexistent', nil)
        result = service.remove

        expect(result[:success]).to be false
        expect(result[:errors]).to be_present
      end
    end
  end
end

