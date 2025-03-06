class StandingsController < ApplicationController
  def index
    league_season = LeagueSeason.find(params[:league_season_id])
    standings = league_season.standings.order(total_points: :desc)

    render json: standings.as_json(include: { user: { only: [:id, :username] } })
  end
end
