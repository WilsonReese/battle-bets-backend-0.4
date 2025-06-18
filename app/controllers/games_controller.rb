class GamesController < ApplicationController
  before_action :authenticate_user!, only: %i[ my_bets ]
  def index
    if params[:week].present? && params[:season_year].present?
      season = Season.find_by(year: params[:season_year].to_i)
      week = params[:week].to_i

      if season.nil?
        render json: { error: "No season found for year #{params[:season_year]}" }, status: :not_found and return
      end

      Rails.logger.debug("🔍 Looking for games in season #{season.id} (#{season.year}) and week #{week}")
      Rails.logger.debug("📆 Available weeks: #{Game.where(season: season).pluck(:week).uniq.inspect}")
      Rails.logger.debug("📦 Matching games: #{Game.where(season: season, week: week).pluck(:id)}")

      @games = Game.where(season: season, week: week)

      render json: @games.as_json(include: {
        home_team: { only: [:name, :conference] },
        away_team: { only: [:name, :conference] },
        bet_options: { only: [:id, :title, :long_title, :payout, :category] }
      })
    else
      render json: { error: "Must provide week and season_year parameters" }, status: :bad_request
    end
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

    render json: bets.as_json(include: {
      bet_option: {
        only: [:id, :title, :long_title, :category, :payout, :success, :bet_flavor],
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
                  pool: {
                    only: [:id, :name]
                  }
                }
              }
            }
          }
        }
      }
    })
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