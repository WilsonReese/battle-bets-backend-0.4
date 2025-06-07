class SeasonsController < ApplicationController
  def index
    if params[:limit] == "1"
      season = Season.order(created_at: :desc).first
      render json: season
    else
      seasons = Season.all.order(created_at: :desc)
      render json: seasons
    end
  end
end