Rails.application.routes.draw do
  get 'leaderboard_entries/index'
  get 'league_seasons/index'
  get 'league_seasons/show'
  get 'games/index'
  get "/current_user", to: "users#current"
  get '/user_reset_status', to: 'users#reset_status'
  get "/ambassadors", to: "ambassadors#index"
  patch "/users/update_profile", to: "users#update_profile"
  patch "/users/change_password", to: "users#change_password"
  devise_for :users, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup',
    password: 'password'
  },
  controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    confirmations: 'users/confirmations',
    passwords: 'users/passwords'
  }
  
  devise_scope :user do
    patch "/password/update", to: "users/passwords#update"
  end
  
  resources :pools, only: %i[index show create update destroy] do
    resources :pool_memberships, only: %i[index create update destroy]

    # LeagueSeasons within a pool
    resources :league_seasons, only: %i[index show create] do
      # Leaderboard Entries for the specific LeagueSeason
      resources :leaderboard_entries, only: %i[index]
      resources :battles, only: %i[index show create update destroy] do
        resources :betslips, only: %i[index show create update destroy] do
          patch 'bets', to: 'bets#update', on: :member
          resources :bets, only: %i[index create destroy]
        end
      end
    end
  end
  
  resources :games, only: %i[index show] do          # ← add :show if you need it
    resources :bet_options, only: [:index]

    member do                                         # /games/:id/*
      get :my_bets                                   # /games/:id/my_bets
      get :league_bets                               # /games/:id/league_bets
    end
  end

  resources :teams, only: :index

  resources :seasons, only: [:index]

  resources :announcements, only: [:index]

  # root to: "home#index"
  root to: proc { [200, { "Content-Type" => "application/json" }, ['{ "message": "API is running" }']] }
end
