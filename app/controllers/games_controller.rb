class GamesController < ApplicationController
  before_action :authenticate_user!, only: %i[ index my_bets ]

  def index
    unless params[:season_year].present?
      return render json: { error: "Must provide season_year parameter" },
                    status: :bad_request
    end

    season = Season.find_by(year: params[:season_year].to_i)
    unless season
      return render json: { error: "No season found for year #{params[:season_year]}" },
                    status: :not_found
    end

    week = season.current_week.to_i

    # 1. Load games for this season/week
    base_games = Game
      .with_bet_options
      .where(season: season, week: week)
      .includes(:home_team, :away_team, :bet_options)
      .to_a

    # 2. Get count of bets placed by the current user, grouped by game
    counts_by_game = Bet
      .joins(:betslip, bet_option: :game)
      .where(
        betslips: { user_id: current_user.id },
        games:    { season_id: season.id, week: week }
      )
      .group("games.id")
      .count  # => { game_id => number of bets }

    # 3. Add user_bet_count method to each game dynamically
    @games = base_games.sort_by { |g|
      [counts_by_game[g.id] ? 0 : 1, g.start_time]
    }.each do |game|
      # virtual field
      game.define_singleton_method(:user_bet_count) { counts_by_game[game.id] || 0 }

      # 🔒 keep bet_options order deterministic
      game.association(:bet_options).target.sort_by!(&:created_at)
    end

    # 4. Render the JSON
    render json: @games.as_json(
      include: {
        home_team:    { only: [:name, :conference] },
        away_team:    { only: [:name, :conference] },
        bet_options:  { only: [:id, :title, :long_title, :payout, :category] }
      },
      methods: [:user_bet_count]
    )
  end

  def my_bets
    game = Game.find(params[:id])

    bets = Bet
      .joins(:betslip, :bet_option)
      .where(betslips: { user_id: current_user.id }, bet_options: { game_id: game.id })
      .includes(
        bet_option: { game: [:home_team, :away_team] },
        betslip: { battle: { league_season: :pool } }
      )

    bets_json = bets.as_json(
      include: {
        bet_option: {
          only: %i[id title long_title category payout success bet_flavor],
          include: {
            game: {
              only: [:start_time],
              include: {
                home_team: { only: [:name] },
                away_team: { only: [:name] }
              }
            }
          }
        },
        betslip: {
          only: [:id],
          include: {
            battle: {
              only: [:id],
              include: {
                league_season: {
                  only: [:id],
                  include: {
                    pool: { only: %i[id name] }
                  }
                }
              }
            }
          }
        }
      }
    )

    render json: {
      bets: bets_json,
      pool_count: current_user.pool_memberships.count
    }
  end

  def league_bets
    game  = Game.find(params[:id])
    pool  = Pool.find(params[:pool_id])

    bets = Bet
            .joins(
              bet_option: :game,
              betslip:   { battle: { league_season: :pool } }
            )
            .where(bet_options: { game_id: game.id })
            .where(pools:      { id: pool.id })
            .includes(
              bet_option: { game: [:home_team, :away_team] },          # <-- eager-load
              betslip:    { battle: { league_season: :pool } }
            )

    render json: bets.as_json(include: {
      bet_option: {
        include: {
          game: {
            include: {
              home_team: { only: :name },
              away_team: { only: :name }
            }
          }
        }
      },
      betslip: {
        include: {
          battle: {
            include: { league_season: { include: :pool } }
          }
        }
      }
    })
  end
end