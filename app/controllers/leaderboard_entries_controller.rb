class LeaderboardEntriesController < ApplicationController
  def index
    league_season = LeagueSeason.find(params[:league_season_id])
    leaderboard_entries = league_season.leaderboard_entries.order(total_points: :desc)

    render json: leaderboard_entries.as_json(include: { user: { only: [:id, :username] } })
  end
end
