require 'rails_helper'

RSpec.describe ApplicationError do
  describe '#initialize' do
    it 'sets message, type, and status_code' do
      error = described_class.new('Test error', type: :test_error, status_code: 400)
      expect(error.message).to eq('Test error')
      expect(error.type).to eq(:test_error)
      expect(error.status_code).to eq(400)
    end
  end

  describe '#to_json' do
    it 'returns structured error JSON' do
      error = described_class.new('Test error', type: :test_error, status_code: 400)
      json_hash = error.to_json
      expect(json_hash[:error][:type]).to eq('test_error')
      expect(json_hash[:error][:message]).to eq('Test error')
    end
  end
end

