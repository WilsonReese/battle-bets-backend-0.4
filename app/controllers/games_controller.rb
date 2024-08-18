class GamesController < ApplicationController
  # def index
  #   @games = Game.all
  #   render json: @games
  # end

  def index
    if params[:battle_id].present?
      battle = Battle.find(params[:battle_id])
      @games = Game.within_date_range(battle.start_date, battle.end_date)

      render json: @games.as_json(include: { 
        game_teams: { include: { team: { only: :name } }, only: :is_home }, 
        bet_options: { only: [:title, :payout, :category] } 
      })
    else
      render json: { error: "battle_id parameter is required" }, status: :bad_request
    end
  end
end