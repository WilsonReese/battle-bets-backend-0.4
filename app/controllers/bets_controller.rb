class BetsController < ApplicationController
    before_action :set_betslip
    before_action :set_bet, only: %i[update destroy]
  
    # GET /betslips/:betslip_id/bets
    def index
      @bets = @betslip.bets
      render json: @bets
    end
  
    # POST /betslips/:betslip_id/bets
    def create
      @bet = @betslip.bets.new(bet_params)
      # @bet.to_win_amount = calculate_to_win_amount(@bet.bet_amount, @bet.bet_option.payout) # Assuming you have a `payout` field in BetOption
      @bet.to_win_amount = 0
  
      if @bet.save
        render json: @bet, status: :created, location: [@betslip.battle.pool, @betslip.battle, @betslip, @bet]
      else
        render json: @bet.errors, status: :unprocessable_entity
      end
    end
  
    # PATCH/PUT /betslips/:betslip_id/bets/:id
    def update
      if @bet.update(bet_params)
        # @bet.update(to_win_amount: calculate_to_win_amount(@bet.bet_amount, @bet.bet_option.payout))
        @bet.update(to_win_amount: 0)
        render json: @bet
      else
        render json: @bet.errors, status: :unprocessable_entity
      end
    end
  
    # DELETE /betslips/:betslip_id/bets/:id
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
  
    # def calculate_to_win_amount(bet_amount, payout)
    #   bet_amount * payout
    # end
end
