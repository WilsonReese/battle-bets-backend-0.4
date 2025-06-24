class GamesController < ApplicationController
  before_action :authenticate_user!, only: %i[ index my_bets ]

  def index
    unless params[:week].present? && params[:season_year].present?
      return render json: { error: "Must provide week and season_year parameters" },
                    status: :bad_request
    end

    season = Season.find_by(year: params[:season_year].to_i)
    unless season
      return render json: { error: "No season found for year #{params[:season_year]}" },
                    status: :not_found
    end

    week = params[:week].to_i

    # 1️⃣ Base set: all games with bet_options in this season/week
    base_games = Game
      .with_bet_options
      .where(season: season, week: week)
      .to_a

    # 2️⃣ Figure out which of those have bets by current_user
    #    We join bets → betslips → bet_options → games to restrict to our same season/week
    bet_game_ids = Bet
      .joins(:betslip, bet_option: :game)
      .where(
        betslips:   { user_id: current_user.id },
        games:       { season_id: season.id, week: week }
      )
      .pluck("games.id")
      .uniq

    # 3️⃣ Sort in Ruby so “bet by user” games come first, then by start_time
    @games = base_games.sort_by do |game|
      [
        bet_game_ids.include?(game.id) ? 0 : 1,
        game.start_time
      ]
    end

    # 4️⃣ Render as before
    render json: @games.as_json(
      include: {
        home_team:  { only: [:name, :conference] },
        away_team:  { only: [:name, :conference] },
        bet_options:{ only: [:id, :title, :long_title, :payout, :category] }
      }
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