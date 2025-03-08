class BattlesController < ApplicationController
    before_action :set_league_season
    before_action :set_battle, only: %i[show update destroy]
  
    # GET /pools/:pool_id/battles
    def index
      @battles = @league_season.battles.order(start_date: :desc)
      render json: @battles.as_json(methods: :betslip_count)
    end
  
    # GET /pools/:pool_id/battles/:id
    def show
      render json: @battle
    end
  
    # POST /pools/:pool_id/battles
    def create
      @battle = @pool.battles.new(battle_params)
  
      if @battle.save
        render json: @battle, status: :created
      else
        render json: @battle.errors, status: :unprocessable_entity
      end
    end
  
    # PATCH/PUT /pools/:pool_id/battles/:id
    def update
      if @battle.update(battle_params)
        render json: @battle
      else
        render json: @battle.errors, status: :unprocessable_entity
      end
    end
  
    # DELETE /pools/:pool_id/battles/:id
    def destroy
      @battle.destroy
      head :no_content
    end
  
    private
  
    def set_league_season
      @league_season = LeagueSeason.find(params[:league_season_id])
    end
  
    def set_battle
      @battle = @league_season.battles.find(params[:id])
    end
  
    def battle_params
      params.require(:battle).permit(:start_date, :end_date)
    end
  end
