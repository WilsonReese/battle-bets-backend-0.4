Rails.application.routes.draw do
  get 'leaderboard_entries/index'
  get 'league_seasons/index'
  get 'league_seasons/show'
  get 'games/index'
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

    # LeagueSeasons within a pool
    resources :league_seasons, only: %i[index show] do
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
  
  resources :games, only: [:index] do
    resources :bet_options, only: [:index]
  end

  resources :teams, only: :index

  # root to: "home#index"
  root to: proc { [200, { "Content-Type" => "application/json" }, ['{ "message": "API is running" }']] }
end
