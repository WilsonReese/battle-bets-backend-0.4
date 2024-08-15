class BetsController < ApplicationController
    before_action :set_betslip
    before_action :set_bet, only: %i[update destroy]
  
    # GET /pools/:pool_id/battles/:battle_id/betslips/:betslip_id/bets
    def index
      @bets = @betslip.bets
      render json: @bets
    end
  
    # POST /pools/:pool_id/battles/:battle_id/betslips/:betslip_id/bets
    def create
      @bet = @betslip.bets.new(bet_params)
  
      if @bet.save
        render json: @bet, status: :created, location: [@betslip.battle.pool, @betslip.battle, @betslip, @bet]
      else
        render json: @bet.errors, status: :unprocessable_entity
      end
    end
  
    # PATCH/PUT /pools/:pool_id/battles/:battle_id/betslips/:betslip_id/bets/:id
    def update
      if @bet.update(bet_params)
        render json: @bet
      else
        render json: @bet.errors, status: :unprocessable_entity
      end
    end
  
    # DELETE /pools/:pool_id/battles/:battle_id/betslips/:betslip_id/bets/:id
    def destroy
      @bet.destroy
      head :no_content
    end
  
    private
  
    def set_betslip
      @betslip = Betslip.find(params[:betslip_id])
    end
  
    def set_bet
      @bet = @betslip.bets.find(params[:id])
    end
  
    def bet_params
      params.require(:bet).permit(:bet_option_id, :bet_amount)
    end
end
