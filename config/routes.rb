Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users, defaults: { format: :json }, skip: :all

  namespace :api do
    namespace :v1 do
      devise_scope :user do
        post   "auth/sign_up", to: "users/registrations#create"
        post   "auth/login",   to: "users/sessions#create"
        delete "auth/logout",  to: "users/sessions#destroy"
      end

      get "analytics/country_salary_statistics", to: "analytics#country_salary_statistics"
      get "analytics/job_title_average_salary", to: "analytics#job_title_average_salary"

      resources :employees
      resources :public_resources, only: [] do
        get :allowed_resource_list, on: :collection
      end
      resources :dashboards, only: :index
    end
  end
end
