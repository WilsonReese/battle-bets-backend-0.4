class BetsController < ApplicationController
    before_action :set_betslip
    before_action :authenticate_user!, only: %i[create update destroy]
    before_action :authorize_betslip_owner!, only: %i[create update destroy]
    before_action :set_bet, only: %i[destroy]
  
    # GET /pools/:pool_id/battles/:battle_id/betslips/:betslip_id/bets
    def index
      @bets = @betslip.bets.includes(:bet_option) # Eager load bet_option
    
      render json: {
        status: @betslip.status,
        bets: @bets.as_json(include: {
          bet_option: { only: [:id, :title, :long_title, :category, :game_id] }
        }),
      }
    end
  
    # POST /pools/:pool_id/battles/:battle_id/betslips/:betslip_id/bets
    # def create
    #   @bet = @betslip.bets.new(bet_params)
  
    #   if @bet.save
    #     render json: @bet, status: :created, location: [@betslip.battle.pool, @betslip.battle, @betslip, @bet]
    #   else
    #     render json: @bet.errors, status: :unprocessable_entity
    #   end
    # end
    
    # POST /pools/:pool_id/battles/:battle_id/betslips/:betslip_id/bets
    def create
      bets = []
      begin
        Bet.transaction do
          bets = bet_params.map do |bet|
            @betslip.bets.create!(bet.permit(:bet_option_id, :bet_amount))
          end
        end
        render json: bets, status: :created, location: [@betslip.battle.pool, @betslip.battle, @betslip]
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end
  
    # PATCH/PUT /pools/:pool_id/battles/:battle_id/betslips/:betslip_id/bets/:id
    # def update
    #   if @bet.update(bet_params)
    #     render json: @bet
    #   else
    #     render json: @bet.errors, status: :unprocessable_entity
    #   end
    # end

    # PATCH/PUT /pools/:pool_id/battles/:battle_id/betslips/:betslip_id/bets/:id
    # def update
    #   begin
    #     Bet.transaction do
    #       @betslip.bets.destroy_all
    
    #       bets = bet_params.map do |bet|
    #         @betslip.bets.create!(bet.permit(:bet_option_id, :bet_amount))
    #       end
    
    #       render json: bets, status: :created, location: [@betslip.battle.pool, @betslip.battle, @betslip]
    #     end
    #   rescue ActiveRecord::RecordInvalid => e
    #     render json: { error: e.message }, status: :unprocessable_entity
    #   end
    # end

    # PATCH/PUT /pools/:pool_id/battles/:battle_id/betslips/:betslip_id/bets
    def update
      begin
        Bet.transaction do
          # Extract new, updated, and removed bets from params
          new_bets = bet_params[:new_bets] || []
          updated_bets = bet_params[:updated_bets] || []
          removed_bet_ids = bet_params[:removed_bet_ids] || []

          # Destroy removed bets
          Bet.where(id: removed_bet_ids).destroy_all if removed_bet_ids.any?

          # Update existing bets
          updated_bets.each do |bet|
            existing_bet = Bet.find(bet[:id])
            existing_bet.update!(bet.permit(:bet_option_id, :bet_amount))
          end

          # Create new bets
          new_bets.each do |bet|
            @betslip.bets.create!(bet.permit(:bet_option_id, :bet_amount))
          end

          # Render the updated bets as the response
          render json: @betslip.bets, status: :ok
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end

    
  
    # DELETE /pools/:pool_id/battles/:battle_id/betslips/:betslip_id/bets/:id
    def destroy
      @bet.destroy
      head :no_content
    end
  
    private
  
    def set_betslip
      @betslip = Betslip.find(params[:betslip_id] || params[:id])
    end
  
    def set_bet
      @bet = @betslip.bets.find(params[:id])
    end

    def authorize_betslip_owner!
      unless @betslip.user == current_user
        render json: { error: 'Unauthorized to modify bets for this betslip' }, status: :forbidden
      end
    end

    def bet_params
      params.require(:bets).permit(
        new_bets: [:bet_option_id, :bet_amount],
        updated_bets: [:id, :bet_option_id, :bet_amount],
        removed_bets: []
      )
    end
  
    # def bet_params
    #   params.require(:bets).map do |bet|
    #     bet.permit(:bet_option_id, :bet_amount)
    #   end
    # end
end


# # PATCH/PUT /pools/:pool_id/battles/:battle_id/betslips/:betslip_id/bets
# def update
#   begin
#     Bet.transaction do
#       # Extract new, updated, and removed bets from params
#       new_bets = bet_params[:new_bets] || []
#       updated_bets = bet_params[:updated_bets] || []
#       removed_bet_ids = bet_params[:removed_bet_ids] || []

#       # Destroy removed bets
#       Bet.where(id: removed_bet_ids).destroy_all if removed_bet_ids.any?

#       # Update existing bets
#       updated_bets.each do |bet|
#         existing_bet = Bet.find(bet[:id])
#         existing_bet.update!(bet.permit(:bet_option_id, :bet_amount))
#       end

#       # Create new bets
#       new_bets.each do |bet|
#         @betslip.bets.create!(bet.permit(:bet_option_id, :bet_amount))
#       end

#       # Render the updated bets as the response
#       render json: @betslip.bets, status: :ok
#     end
#   rescue ActiveRecord::RecordInvalid => e
#     render json: { error: e.message }, status: :unprocessable_entity
#   end
# end

# private

# def bet_params
#   params.require(:bets).permit(
#     new_bets: [:bet_option_id, :bet_amount],
#     updated_bets: [:id, :bet_option_id, :bet_amount],
#     removed_bet_ids: []
#   )
# end