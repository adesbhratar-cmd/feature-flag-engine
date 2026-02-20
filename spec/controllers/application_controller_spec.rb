require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def test_application_error
      raise ApplicationError.new('Test error', type: :test_error, status_code: 400)
    end

    def test_not_found
      raise ActiveRecord::RecordNotFound
    end

    def test_validation_error
      feature_flag = FeatureFlag.new
      feature_flag.save!
    end

    def test_argument_error
      raise ArgumentError, 'Invalid argument'
    end
  end

  before do
    routes.draw do
      get 'test_application_error' => 'anonymous#test_application_error'
      get 'test_not_found' => 'anonymous#test_not_found'
      get 'test_validation_error' => 'anonymous#test_validation_error'
      get 'test_argument_error' => 'anonymous#test_argument_error'
    end
  end

  describe 'error handling' do
    it 'handles ApplicationError' do
      get :test_application_error
      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['error']).to be_present
    end

    it 'handles RecordNotFound' do
      get :test_not_found
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['error']).to be_present
    end

    it 'handles RecordInvalid' do
      get :test_validation_error
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['error']).to be_present
    end

    it 'handles ArgumentError' do
      get :test_argument_error
      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['error']).to be_present
    end
  end
end

