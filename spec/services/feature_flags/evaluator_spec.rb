require 'rails_helper'

RSpec.describe FeatureFlags::Evaluator do
  let(:feature_flag) { create(:feature_flag, global_default_state: false) }

  describe '#evaluate' do
    context 'with no context' do
      it 'returns global default state' do
        evaluator = described_class.new(feature_flag: feature_flag, context: {})
        expect(evaluator.evaluate).to eq(false)
      end
    end

    context 'with user override' do
      it 'returns user override value when user override exists' do
        create(:user_override, feature_flag: feature_flag, user_id: 'user1', enabled: true)
        evaluator = described_class.new(feature_flag: feature_flag, context: { user_id: 'user1' })
        expect(evaluator.evaluate).to eq(true)
      end

      it 'prioritizes user override over group override' do
        create(:user_override, feature_flag: feature_flag, user_id: 'user1', enabled: true)
        create(:group_override, feature_flag: feature_flag, group_id: 'group1', enabled: false)
        evaluator = described_class.new(
          feature_flag: feature_flag,
          context: { user_id: 'user1', group_id: 'group1' }
        )
        expect(evaluator.evaluate).to eq(true)
      end

      it 'prioritizes user override over region override' do
        create(:user_override, feature_flag: feature_flag, user_id: 'user1', enabled: true)
        create(:region_override, feature_flag: feature_flag, region: 'us-east', enabled: false)
        evaluator = described_class.new(
          feature_flag: feature_flag,
          context: { user_id: 'user1', region: 'us-east' }
        )
        expect(evaluator.evaluate).to eq(true)
      end
    end

    context 'with group override' do
      it 'returns group override value when group override exists' do
        create(:group_override, feature_flag: feature_flag, group_id: 'group1', enabled: true)
        evaluator = described_class.new(feature_flag: feature_flag, context: { group_id: 'group1' })
        expect(evaluator.evaluate).to eq(true)
      end

      it 'prioritizes group override over region override' do
        create(:group_override, feature_flag: feature_flag, group_id: 'group1', enabled: true)
        create(:region_override, feature_flag: feature_flag, region: 'us-east', enabled: false)
        evaluator = described_class.new(
          feature_flag: feature_flag,
          context: { group_id: 'group1', region: 'us-east' }
        )
        expect(evaluator.evaluate).to eq(true)
      end

      it 'falls back to global default when group override does not exist' do
        evaluator = described_class.new(feature_flag: feature_flag, context: { group_id: 'nonexistent' })
        expect(evaluator.evaluate).to eq(false)
      end
    end

    context 'with region override' do
      it 'returns region override value when region override exists' do
        create(:region_override, feature_flag: feature_flag, region: 'us-east', enabled: true)
        evaluator = described_class.new(feature_flag: feature_flag, context: { region: 'us-east' })
        expect(evaluator.evaluate).to eq(true)
      end

      it 'falls back to global default when region override does not exist' do
        evaluator = described_class.new(feature_flag: feature_flag, context: { region: 'nonexistent' })
        expect(evaluator.evaluate).to eq(false)
      end
    end

    context 'evaluation precedence' do
      it 'follows correct precedence: user > group > region > global' do
        feature_flag.update(global_default_state: false)
        create(:region_override, feature_flag: feature_flag, region: 'us-east', enabled: true)
        create(:group_override, feature_flag: feature_flag, group_id: 'group1', enabled: false)
        create(:user_override, feature_flag: feature_flag, user_id: 'user1', enabled: true)

        evaluator = described_class.new(
          feature_flag: feature_flag,
          context: { user_id: 'user1', group_id: 'group1', region: 'us-east' }
        )
        expect(evaluator.evaluate).to eq(true) # User override wins
      end
    end

    context 'with caching' do
      before do
        Rails.cache.clear
      end

      it 'caches evaluation results' do
        # Create override before first evaluation
        create(:user_override, feature_flag: feature_flag, user_id: 'user1', enabled: true)
        
        evaluator = described_class.new(feature_flag: feature_flag, context: { user_id: 'user1' })
        first_result = evaluator.evaluate
        expect(first_result).to eq(true)

        # Update override after caching
        UserOverride.find_by(user_id: 'user1', feature_flag: feature_flag).update(enabled: false)

        # Should still return cached result (true) until cache expires
        second_result = evaluator.evaluate
        expect(second_result).to eq(true) # Cached result
      end
    end

    context 'case insensitivity' do
      it 'handles case-insensitive user_id' do
        create(:user_override, feature_flag: feature_flag, user_id: 'user1', enabled: true)
        evaluator = described_class.new(feature_flag: feature_flag, context: { user_id: 'USER1' })
        expect(evaluator.evaluate).to eq(true)
      end

      it 'handles case-insensitive group_id' do
        create(:group_override, feature_flag: feature_flag, group_id: 'group1', enabled: true)
        evaluator = described_class.new(feature_flag: feature_flag, context: { group_id: 'GROUP1' })
        expect(evaluator.evaluate).to eq(true)
      end

      it 'handles case-insensitive region' do
        create(:region_override, feature_flag: feature_flag, region: 'us-east', enabled: true)
        evaluator = described_class.new(feature_flag: feature_flag, context: { region: 'US-EAST' })
        expect(evaluator.evaluate).to eq(true)
      end
    end
  end

  describe '#evaluate_with_metadata' do
    it 'returns evaluation result with metadata' do
      evaluator = described_class.new(feature_flag: feature_flag, context: {})
      result = evaluator.evaluate_with_metadata

      expect(result).to have_key(:enabled)
      expect(result).to have_key(:source)
      expect(result).to have_key(:feature_flag_name)
      expect(result[:source]).to eq(:global)
    end

    it 'indicates user override source' do
      create(:user_override, feature_flag: feature_flag, user_id: 'user1', enabled: true)
      evaluator = described_class.new(feature_flag: feature_flag, context: { user_id: 'user1' })
      result = evaluator.evaluate_with_metadata

      expect(result[:enabled]).to eq(true)
      expect(result[:source]).to eq(:user)
    end

    it 'indicates group override source' do
      create(:group_override, feature_flag: feature_flag, group_id: 'group1', enabled: true)
      evaluator = described_class.new(feature_flag: feature_flag, context: { group_id: 'group1' })
      result = evaluator.evaluate_with_metadata

      expect(result[:enabled]).to eq(true)
      expect(result[:source]).to eq(:group)
    end

    it 'indicates region override source' do
      create(:region_override, feature_flag: feature_flag, region: 'us-east', enabled: true)
      evaluator = described_class.new(feature_flag: feature_flag, context: { region: 'us-east' })
      result = evaluator.evaluate_with_metadata

      expect(result[:enabled]).to eq(true)
      expect(result[:source]).to eq(:region)
    end

    it 'indicates global default source' do
      evaluator = described_class.new(feature_flag: feature_flag, context: {})
      result = evaluator.evaluate_with_metadata

      expect(result[:enabled]).to eq(false)
      expect(result[:source]).to eq(:global)
    end
  end

  describe 'edge cases' do
    it 'handles nil context values' do
      evaluator = described_class.new(feature_flag: feature_flag, context: { user_id: nil, group_id: nil })
      expect(evaluator.evaluate).to eq(false)
    end

    it 'handles empty string context values' do
      evaluator = described_class.new(feature_flag: feature_flag, context: { user_id: '', group_id: '' })
      expect(evaluator.evaluate).to eq(false)
    end

    it 'handles whitespace-only context values' do
      evaluator = described_class.new(feature_flag: feature_flag, context: { user_id: '   ', group_id: '   ' })
      expect(evaluator.evaluate).to eq(false)
    end

    it 'handles enabled global default' do
      enabled_flag = create(:feature_flag, global_default_state: true)
      evaluator = described_class.new(feature_flag: enabled_flag, context: {})
      expect(evaluator.evaluate).to eq(true)
    end
  end
end

