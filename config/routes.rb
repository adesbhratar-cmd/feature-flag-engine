Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      resources :feature_flags do
        member do
          post :evaluate
          get :overrides
        end
      end
      resources :feature_flags, only: [] do
        member do
          post 'overrides', to: 'overrides#create'
          delete 'overrides', to: 'overrides#destroy'
        end
      end
    end
  end
end
