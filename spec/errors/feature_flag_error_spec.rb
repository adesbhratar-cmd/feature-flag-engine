require 'rails_helper'

RSpec.describe FeatureFlagError do
  describe '#initialize' do
    it 'sets default status code to 400' do
      error = described_class.new('Error message')
      expect(error.status_code).to eq(400)
      expect(error.type).to eq(:feature_flag_error)
    end

    it 'allows custom status code' do
      error = described_class.new('Error message', status_code: 404)
      expect(error.status_code).to eq(404)
    end
  end
end

RSpec.describe FeatureFlagNotFoundError do
  describe '#initialize' do
    it 'sets correct message and status code' do
      error = described_class.new('missing_flag')
      expect(error.message).to include('missing_flag')
      expect(error.status_code).to eq(404)
      expect(error.type).to eq(:feature_flag_error)
    end
  end
end

RSpec.describe ValidationError do
  describe '#initialize' do
    it 'handles array of errors' do
      errors = ['Error 1', 'Error 2']
      error = described_class.new(errors)
      expect(error.message).to include('Error 1')
      expect(error.status_code).to eq(422)
    end

    it 'handles string error' do
      error = described_class.new('Single error')
      expect(error.message).to eq('Single error')
    end
  end

  describe '#to_json' do
    it 'includes details array' do
      errors = ['Error 1', 'Error 2']
      error = described_class.new(errors)
      json_hash = error.to_json
      expect(json_hash[:error][:details]).to be_an(Array)
      expect(json_hash[:error][:details].length).to eq(2)
    end
  end
end

