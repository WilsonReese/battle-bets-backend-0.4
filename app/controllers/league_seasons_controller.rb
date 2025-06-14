class LeagueSeasonsController < ApplicationController
  def index
    pool = Pool.find(params[:pool_id])
    league_seasons = pool.league_seasons

    render json: league_seasons.as_json(
      include: {
        season: { only: [:year, :start_date, :end_date, :current_week] }
      },
      methods: [:has_started?]
    )
  end

  def show
    league_season = LeagueSeason.find(params[:id])
    render json: league_season
  end

  def create
    pool = Pool.find(params[:pool_id])
    league_season = pool.league_seasons.new(league_season_params)

    if league_season.save
      render json: league_season, status: :created
    else
      render json: league_season.errors, status: :unprocessable_entity
    end
  end


  private

  def league_season_params
    params.require(:league_season).permit(:start_week)
  end
end
