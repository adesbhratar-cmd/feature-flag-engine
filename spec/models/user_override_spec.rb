require 'rails_helper'

RSpec.describe UserOverride, type: :model do
  describe 'associations' do
    it { should belong_to(:feature_flag) }
  end

  describe 'validations' do
    subject { build(:user_override) }

    it { should validate_presence_of(:user_id) }
    it { should validate_inclusion_of(:enabled).in_array([true, false]) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:feature_flag_id).case_insensitive }
  end

  describe 'scopes' do
    let(:feature_flag) { create(:feature_flag) }

    describe '.for_user' do
      it 'returns overrides for a specific user' do
        override1 = create(:user_override, feature_flag: feature_flag, user_id: 'user1')
        override2 = create(:user_override, feature_flag: feature_flag, user_id: 'user2')

        expect(UserOverride.for_user('user1')).to include(override1)
        expect(UserOverride.for_user('user1')).not_to include(override2)
      end
    end

    describe '.enabled' do
      it 'returns only enabled overrides' do
        enabled_override = create(:user_override, :enabled, feature_flag: feature_flag)
        disabled_override = create(:user_override, :disabled, feature_flag: feature_flag)

        expect(UserOverride.enabled).to include(enabled_override)
        expect(UserOverride.enabled).not_to include(disabled_override)
      end
    end
  end

  describe 'callbacks' do
    describe 'before_save :normalize_user_id' do
      it 'normalizes user_id to lowercase' do
        override = build(:user_override, user_id: 'USER123')
        override.save
        expect(override.user_id).to eq('user123')
      end

      it 'strips whitespace from user_id' do
        override = build(:user_override, user_id: '  user123  ')
        override.save
        expect(override.user_id).to eq('user123')
      end
    end
  end

  describe 'uniqueness validation' do
    let(:feature_flag) { create(:feature_flag) }

    it 'prevents duplicate user overrides for the same feature flag' do
      create(:user_override, feature_flag: feature_flag, user_id: 'user1')
      duplicate = build(:user_override, feature_flag: feature_flag, user_id: 'user1')
      expect(duplicate).not_to be_valid
    end

    it 'allows same user_id for different feature flags' do
      feature_flag2 = create(:feature_flag)
      create(:user_override, feature_flag: feature_flag, user_id: 'user1')
      override2 = build(:user_override, feature_flag: feature_flag2, user_id: 'user1')
      expect(override2).to be_valid
    end
  end
end
