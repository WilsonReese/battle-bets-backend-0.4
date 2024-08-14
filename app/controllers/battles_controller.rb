class BattlesController < ApplicationController
    before_action :set_pool
    before_action :set_battle, only: %i[show update destroy]
  
    # GET /pools/:pool_id/battles
    def index
      @battles = @pool.battles
      render json: @battles
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
  
    def set_pool
      @pool = Pool.find(params[:pool_id])
    end
  
    def set_battle
      @battle = @pool.battles.find(params[:id])
    end
  
    def battle_params
      params.require(:battle).permit(:start_date, :end_date)
    end
  end