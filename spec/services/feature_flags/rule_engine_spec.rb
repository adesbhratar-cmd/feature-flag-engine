require 'rails_helper'

RSpec.describe FeatureFlags::RuleEngine do
  let(:feature_flag) { create(:feature_flag, global_default_state: false) }

  describe '#evaluate' do
    context 'with no overrides' do
      it 'returns global default state' do
        engine = described_class.new(feature_flag: feature_flag, context: {})
        expect(engine.evaluate).to eq(false)
      end
    end

    context 'with user override' do
      it 'returns user override value' do
        create(:user_override, feature_flag: feature_flag, user_id: 'user1', enabled: true)
        engine = described_class.new(feature_flag: feature_flag, context: { user_id: 'user1' })
        expect(engine.evaluate).to eq(true)
      end

      it 'prioritizes user override over group override' do
        create(:user_override, feature_flag: feature_flag, user_id: 'user1', enabled: true)
        create(:group_override, feature_flag: feature_flag, group_id: 'group1', enabled: false)
        engine = described_class.new(
          feature_flag: feature_flag,
          context: { user_id: 'user1', group_id: 'group1' }
        )
        expect(engine.evaluate).to eq(true)
      end
    end

    context 'with group override' do
      it 'returns group override value' do
        create(:group_override, feature_flag: feature_flag, group_id: 'group1', enabled: true)
        engine = described_class.new(feature_flag: feature_flag, context: { group_id: 'group1' })
        expect(engine.evaluate).to eq(true)
      end

      it 'prioritizes group override over region override' do
        create(:group_override, feature_flag: feature_flag, group_id: 'group1', enabled: true)
        create(:region_override, feature_flag: feature_flag, region: 'us-east', enabled: false)
        engine = described_class.new(
          feature_flag: feature_flag,
          context: { group_id: 'group1', region: 'us-east' }
        )
        expect(engine.evaluate).to eq(true)
      end
    end

    context 'with region override' do
      it 'returns region override value' do
        create(:region_override, feature_flag: feature_flag, region: 'us-east', enabled: true)
        engine = described_class.new(feature_flag: feature_flag, context: { region: 'us-east' })
        expect(engine.evaluate).to eq(true)
      end
    end

    context 'evaluation precedence' do
      it 'follows correct precedence: user > group > region > global' do
        feature_flag.update(global_default_state: false)
        create(:region_override, feature_flag: feature_flag, region: 'us-east', enabled: true)
        create(:group_override, feature_flag: feature_flag, group_id: 'group1', enabled: false)
        create(:user_override, feature_flag: feature_flag, user_id: 'user1', enabled: true)

        engine = described_class.new(
          feature_flag: feature_flag,
          context: { user_id: 'user1', group_id: 'group1', region: 'us-east' }
        )
        expect(engine.evaluate).to eq(true) # User override wins
      end
    end
  end
end

