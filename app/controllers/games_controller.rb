class GamesController < ApplicationController
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
end