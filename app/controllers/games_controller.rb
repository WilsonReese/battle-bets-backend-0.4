class GamesController < ApplicationController
  def index
    if params[:battle_id].present?
      battle = Battle.find(params[:battle_id])
      @games = Game.within_date_range(battle.start_date, battle.end_date)

    elsif params[:week].present? && params[:season_year].present?
      season = Season.find_by(year: params[:season_year])
      if season.nil?
        render json: { error: "No season found for year #{params[:season_year]}" }, status: :not_found and return
      end

      Rails.logger.debug("🔍 Looking for games in season #{season.id} (#{season.year}) and week #{params[:week]}")
      Rails.logger.debug("🔍 Existing game weeks: #{Game.where(season: season).pluck(:week).uniq.inspect}")
      Rails.logger.debug("🔍 Existing game season_ids: #{Game.distinct.pluck(:season_id)}")

      @games = Game.where(season: season, week: params[:week])

    else
      render json: { error: "Must provide either battle_id or week + season_year" }, status: :bad_request and return
    end

    render json: @games.as_json(include: {
      home_team: { only: :name },
      away_team: { only: :name },
      bet_options: { only: [:id, :title, :long_title, :payout, :category] }
    })
  end
end