class BetslipsController < ApplicationController
    before_action :set_battle
    before_action :set_betslip, only: %i[show update destroy]
    before_action :authenticate_user!, only: %i[create index update]
  
    # GET /battles/:battle_id/betslips
    def index
      if params[:user_only] == 'true'
        # Return only the betslip for the current user
        @betslip = @battle.betslips.find_by(user: current_user)
        
        render json: @betslip.as_json(include: {
          bets: {
            only: [:id, :bet_amount, :to_win_amount, :amount_won],
            include: {
              bet_option: {
                only: [:title, :long_title, :payout, :category, :success],
                include: {
                  game: {
                    only: [:id, :start_time],
                    include: {
                      home_team: { only: [:name] },
                      away_team: { only: [:name] }
                    }
                  }
                }
              }
            }
          }
        })
      else
        # Return all betslips for the battle
        @betslips = @battle.betslips.includes(bets: { bet_option: :game })
  
        render json: @betslips.as_json(include: {
          bets: {
            only: [:id, :bet_amount, :to_win_amount, :amount_won],
            include: {
              bet_option: {
                only: [:title, :long_title, :payout, :category, :success],
                include: {
                  game: {
                    only: [:start_time],
                    include: {
                      home_team: { only: [:name] },
                      away_team: { only: [:name] }
                    }
                  }
                }
              }
            }
          }
        })
      end
    end
  
    # GET /battles/:battle_id/betslips/:id
    def show
      render json: @betslip
    end
  
    # POST /battles/:battle_id/betslips
    def create
      @betslip = @battle.betslips.new(betslip_params)
      if current_user.present?
        @betslip.user = current_user
      else
        render json: { error: "User not authenticated" }, status: :unauthorized
        return
      end

      if @battle.locked?
        render json: { error: "Cannot create a betslip for a locked battle." }, status: :forbidden
        return
      end
  
      if @betslip.save
        render json: @betslip, status: :created
      else
        render json: @betslip.errors, status: :unprocessable_entity
      end
    end
  
    # PATCH/PUT /battles/:battle_id/betslips/:id
    def update
      if @betslip.user != current_user
        render json: { error: "Unauthorized to update this betslip" }, status: :forbidden
        return
      end
  
      if @betslip.update(betslip_params)
        render json: @betslip
      else
        render json: @betslip.errors, status: :unprocessable_entity
      end
    end
  
    # DELETE /battles/:battle_id/betslips/:id
    def destroy
      if @betslip.user != current_user
        render json: { error: "Unauthorized to delete this betslip" }, status: :forbidden
        return
      end
  
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
      params.require(:betslip).permit(:name, :status)
    end
  end
  