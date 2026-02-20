require 'rails_helper'

RSpec.describe RegionOverride, type: :model do
  describe 'associations' do
    it { should belong_to(:feature_flag) }
  end

  describe 'validations' do
    subject { build(:region_override) }

    it { should validate_presence_of(:region) }
    it { should validate_inclusion_of(:enabled).in_array([true, false]) }
    it { should validate_uniqueness_of(:region).scoped_to(:feature_flag_id).case_insensitive }
  end

  describe 'scopes' do
    let(:feature_flag) { create(:feature_flag) }

    describe '.for_region' do
      it 'returns overrides for a specific region' do
        override1 = create(:region_override, feature_flag: feature_flag, region: 'us-east')
        override2 = create(:region_override, feature_flag: feature_flag, region: 'us-west')

        expect(RegionOverride.for_region('us-east')).to include(override1)
        expect(RegionOverride.for_region('us-east')).not_to include(override2)
      end
    end
  end

  describe 'callbacks' do
    describe 'before_save :normalize_region' do
      it 'normalizes region to lowercase' do
        override = build(:region_override, region: 'US-EAST')
        override.save
        expect(override.region).to eq('us-east')
      end
    end
  end
end
