Rails.application.routes.draw do
  get 'leaderboard_entries/index'
  get 'league_seasons/index'
  get 'league_seasons/show'
  get 'games/index'
  resource :user, only: [:destroy]
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
    collection do
      get :community_league
    end
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

  namespace :api do
    namespace :v1 do
      # proxy for api-sports-io games endpoint
      get 'api_sports/games', to: 'api_sports#games'

      # new team-statistics proxy
      get 'api_sports/game_statistics/teams', to: 'api_sports#team_statistics'

      # new player-statistics proxy
      get 'api_sports/game_statistics/players', to: 'api_sports#player_statistics'

      # and later, if you add teams:
      # get 'api_sports/teams',  to: 'api_sports#teams'
    end
  end

  # namespace :diag do
  #   post :compact, to: "diag#compact"
  #   get  :mem,     to: "diag#mem"     # optional, used in step 2
  # end
  post "diag/compact", to: "diag#compact"
  get  "diag/mem",     to: "diag#mem"
  get "/diag/owner", to: "diag#owner"
  get "/diag/holders", to: "diag#holders"
  get "/diag/thread_refs", to: "diag#thread_refs"
  get "/diag/thread_path", to: "diag#thread_path"
  get "/diag/fiber_owner", to: "diag#fiber_owner"
  get "/diag/fiber_pinpoint", to: "diag#fiber_pinpoint"
  get "/diag/pin_env", to: "diag#pin_env"
  get "/diag/pin_response_holders", to: "diag#pin_response_holders"
  get "/diag/array_path", to: "diag#array_path"
  get "/diag/probe_after", to: "diag#probe_after"
  get "/diag/probe_after_path", to: "diag#probe_after_path"
  get "/diag/fiber_edges", to: "diag#fiber_edges"



  # root to: "home#index"
  root to: proc { [200, { "Content-Type" => "application/json" }, ['{ "message": "API is running" }']] }
end
