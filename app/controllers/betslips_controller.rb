class BetslipsController < ApplicationController
    before_action :set_battle
    before_action :set_betslip, only: %i[show update destroy]
  
    # GET /battles/:battle_id/betslips
    def index
      @betslips = @battle.betslips
      render json: @betslips
    end
  
    # GET /battles/:battle_id/betslips/:id
    def show
      render json: @betslip
    end
  
    # POST /battles/:battle_id/betslips
    def create
      @betslip = @battle.betslips.new(betslip_params)
      @betslip.user = current_user
  
      if @betslip.save
        render json: @betslip, status: :created, location: [@battle.pool, @battle, @betslip]
      else
        render json: @betslip.errors, status: :unprocessable_entity
      end
    end
  
    # PATCH/PUT /battles/:battle_id/betslips/:id
    def update
      if @betslip.update(betslip_params)
        render json: @betslip
      else
        render json: @betslip.errors, status: :unprocessable_entity
      end
    end
  
    # DELETE /battles/:battle_id/betslips/:id
    def destroy
      @betslip.destroy
      head :no_content
    end
  
    private
  
    def set_battle
      @battle = Battle.find(params[:battle_id])
    end
  
    def set_betslip
      @betslip = @battle.betslips.find(params[:id])
    end
  
    def betslip_params
      params.require(:betslip).permit(:name)
    end
  end
  