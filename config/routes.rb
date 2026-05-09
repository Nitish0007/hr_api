Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :employees
      resources :public_resources, only: [] do
        get :allowed_resource_list, on: :collection
      end
    end
  end
end
