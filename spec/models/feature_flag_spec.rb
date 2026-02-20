require 'rails_helper'

RSpec.describe FeatureFlag, type: :model do
  describe 'associations' do
    it { should have_many(:user_overrides).dependent(:destroy) }
    it { should have_many(:group_overrides).dependent(:destroy) }
    it { should have_many(:region_overrides).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:feature_flag) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
    it { should validate_inclusion_of(:global_default_state).in_array([true, false]) }
  end

  describe 'scopes' do
    describe '.enabled_by_default' do
      it 'returns feature flags with global_default_state true' do
        enabled_flag = create(:feature_flag, :enabled)
        disabled_flag = create(:feature_flag, :disabled)

        expect(FeatureFlag.enabled_by_default).to include(enabled_flag)
        expect(FeatureFlag.enabled_by_default).not_to include(disabled_flag)
      end
    end

    describe '.disabled_by_default' do
      it 'returns feature flags with global_default_state false' do
        enabled_flag = create(:feature_flag, :enabled)
        disabled_flag = create(:feature_flag, :disabled)

        expect(FeatureFlag.disabled_by_default).to include(disabled_flag)
        expect(FeatureFlag.disabled_by_default).not_to include(enabled_flag)
      end
    end
  end

  describe 'callbacks' do
    describe 'before_save :normalize_name' do
      it 'normalizes name to lowercase' do
        feature_flag = build(:feature_flag, name: 'MY_FEATURE')
        feature_flag.save
        expect(feature_flag.name).to eq('my_feature')
      end

      it 'strips whitespace from name' do
        feature_flag = build(:feature_flag, name: '  my_feature  ')
        feature_flag.save
        expect(feature_flag.name).to eq('my_feature')
      end
    end
  end

  describe 'validations edge cases' do
    it 'rejects duplicate names with different cases' do
      create(:feature_flag, name: 'my_feature')
      duplicate = build(:feature_flag, name: 'MY_FEATURE')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present
    end

    it 'requires global_default_state to be boolean' do
      feature_flag = build(:feature_flag, global_default_state: nil)
      expect(feature_flag).not_to be_valid
    end
  end
end
