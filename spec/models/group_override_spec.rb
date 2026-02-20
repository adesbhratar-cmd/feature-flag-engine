require 'rails_helper'

RSpec.describe GroupOverride, type: :model do
  describe 'associations' do
    it { should belong_to(:feature_flag) }
  end

  describe 'validations' do
    subject { build(:group_override) }

    it { should validate_presence_of(:group_id) }
    it { should validate_inclusion_of(:enabled).in_array([true, false]) }
    it { should validate_uniqueness_of(:group_id).scoped_to(:feature_flag_id).case_insensitive }
  end

  describe 'scopes' do
    let(:feature_flag) { create(:feature_flag) }

    describe '.for_group' do
      it 'returns overrides for a specific group' do
        override1 = create(:group_override, feature_flag: feature_flag, group_id: 'group1')
        override2 = create(:group_override, feature_flag: feature_flag, group_id: 'group2')

        expect(GroupOverride.for_group('group1')).to include(override1)
        expect(GroupOverride.for_group('group1')).not_to include(override2)
      end
    end
  end

  describe 'callbacks' do
    describe 'before_save :normalize_group_id' do
      it 'normalizes group_id to lowercase' do
        override = build(:group_override, group_id: 'GROUP123')
        override.save
        expect(override.group_id).to eq('group123')
      end
    end
  end
end
