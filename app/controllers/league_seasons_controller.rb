class LeagueSeasonsController < ApplicationController
  def index
    pool = Pool.find(params[:pool_id])
    league_seasons = pool.league_seasons

    render json: league_seasons.as_json(include: { season: { only: [:year, :start_date, :end_date] } })
  end

  def show
    league_season = LeagueSeason.find(params[:id])
    render json: league_season
  end
end
