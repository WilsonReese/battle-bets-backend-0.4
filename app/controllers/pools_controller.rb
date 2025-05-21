class PoolsController < ApplicationController
  before_action :set_pool, only: %i[show update destroy]
  before_action :authenticate_user!, only: %i[index show create update destroy]
  before_action :authorize_commissioner!, only: %i[update destroy]

  # GET /pools
  def index
    begin
      Rails.logger.info "Attempting to fetch pools for user: #{current_user.inspect}"
      @pools = current_user.pools.includes(:pool_memberships, :league_seasons)

      enriched_pools = @pools.map do |pool|
        league_season = pool.league_seasons.find { |s| s.season.year == 2024 }

        pool.as_json.merge({
          membership_count: pool.pool_memberships.size,
          start_week: league_season&.start_week,
          has_started: league_season&.has_started?
        })
      end

      render json: enriched_pools
    rescue => e
      Rails.logger.error "Error in PoolsController#index: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: "Internal Server Error" }, status: :internal_server_error
    end
  end

  # GET /pools/:id
  def show
    render json: @pool
  end

  # POST /pools
  def create
    ActiveRecord::Base.transaction do
      @pool = Pool.new(pool_params.except(:start_week))
      @pool.save!
  
      season = Season.find_by!(year: 2024) # Hard code
      @pool.league_seasons.create!(
        season: season,
        start_week: params[:start_week]
      )

      @pool.pool_memberships.create!(
        user: current_user,
        is_commissioner: true
      )
  
      render json: @pool, status: :created, location: @pool
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # PATCH/PUT /pools/:id
  def update
    ActiveRecord::Base.transaction do
      @pool.update!(pool_params)
  
      if params[:start_week]
        season = Season.find_by!(year: 2024)  # find the actual Season record
        league_season = @pool.league_seasons.find_by(season: season)
        
        if league_season
          league_season.update!(start_week: params[:start_week])
        else
          Rails.logger.warn("No LeagueSeason found for pool #{@pool.id} and season #{season.id}")
        end
      end
    end
  
    render json: @pool
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # DELETE /pools/:id
  def destroy
    @pool.destroy
  end

  private

  def set_pool
    @pool = Pool.find(params[:id])
  end

  def pool_params
    params.require(:pool).permit(:name, :start_week)
  end

  def authorize_commissioner!
    membership = @pool.pool_memberships.find_by(user_id: current_user.id)
  
    unless membership&.is_commissioner
      render json: { error: "Only commissioners can perform this action." }, status: :forbidden
    end
  end
end

