Rails.application.routes.draw do
  devise_for :users, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup'
  },
  controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
  
  resources :pools, only: %i[index show create update destroy] do
    resources :pool_memberships, only: %i[index create destroy]
    resources :battles, only: %i[index show create update destroy] do
      resources :betslips, only: %i[index show create update destroy]
    end
  end

  # root to: "home#index"
end
