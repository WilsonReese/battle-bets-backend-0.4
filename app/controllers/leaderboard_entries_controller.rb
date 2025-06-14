class LeaderboardEntriesController < ApplicationController
  before_action :authenticate_user! # Ensures user is authenticated

  def index
    league_season = LeagueSeason.find(params[:league_season_id])

    if params[:user_only] == 'true'
      # Return only the leaderboard entry for the current user
      leaderboard_entry = league_season.leaderboard_entries.find_by(user: current_user)

      if leaderboard_entry
        render json: leaderboard_entry.as_json(
          only: [:id, :total_points, :ranking],
          include: { user: { only: [:id, :username, :first_name, :last_name] } }
        )
      else
        render json: { error: "Leaderboard entry not found for current user." }, status: :not_found
      end
    else
      # Return full standings
      leaderboard_entries = league_season.leaderboard_entries.includes(:user).order(:ranking)

      render json: leaderboard_entries.as_json(
        only: [:id, :total_points, :ranking],
        include: { user: { only: [:id, :username, :first_name, :last_name] } }
      )
    end
  end
end
