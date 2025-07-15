class BetsController < ApplicationController
  before_action :authenticate_user!, only: %i[create update destroy]
  before_action :set_betslip
  before_action :authorize_betslip_owner!, only: %i[create update destroy]

  # GET /…/betslips/:betslip_id/bets
  def index
    @bets = @betslip.bets.includes(bet_option: :game)
    render json: {
      status: @betslip.status,
      bets: @bets.as_json(
        include: {
          bet_option: {
            only: [:id, :title, :long_title, :category, :payout],
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
      )
    }
  end

  # POST   /…/betslips/:betslip_id/bets
  # Accepts a payload of the form:
  #   { bets: { new_bets: [ { bet_option_id:, bet_amount: }, … ] } }
  def create
    ActiveRecord::Base.transaction do
      # we only deal with new_bets here
      new_bets = bet_params.fetch(:new_bets, [])
      new_bets.each do |attrs|
        @betslip.bets.create!(attrs.permit(:bet_option_id, :bet_amount))
      end

      # run your total-budget validation on the parent
      @betslip.save!
    end

    render json: @betslip.bets, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  # PATCH  /…/betslips/:betslip_id/bets
  # Payload shape:
  #   {
  #     bets: {
  #       new_bets:     [ { bet_option_id:, bet_amount: }, … ],
  #       updated_bets: [ { id:,           bet_option_id:, bet_amount: }, … ],
  #       removed_bets: [ id1, id2, … ]
  #     }
  #   }
  def update
    ActiveRecord::Base.transaction do
      new_bets     = bet_params.fetch(:new_bets, [])
      updated_bets = bet_params.fetch(:updated_bets, [])
      removed_bets = bet_params.fetch(:removed_bets, [])

      # 1) remove
      Bet.where(id: removed_bets).destroy_all if removed_bets.any?

      # 2) update
      updated_bets.each do |attrs|
        bet = @betslip.bets.find(attrs[:id])
        bet.update!(attrs.permit(:bet_option_id, :bet_amount))
      end

      # 3) create
      new_bets.each do |attrs|
        @betslip.bets.build(attrs.permit(:bet_option_id, :bet_amount))
      end

      # 4) enforce per-category totals validator
      @betslip.save!
    end

    render json: @betslip.bets, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  # DELETE /…/betslips/:betslip_id/bets/:id
  def destroy
    @bet = @betslip.bets.find(params[:id])
    @bet.destroy!
    head :no_content
  end

  private

  def set_betslip
    # @betslip = Betslip.find(params[:id])
    id = params[:betslip_id] || params[:id]
    @betslip = Betslip.find(id)
  end

  def authorize_betslip_owner!
    unless @betslip.user == current_user
      render json: { error: "Not authorized" }, status: :forbidden
    end
  end

  def bet_params
    params.require(:bets).permit(
      new_bets:     [:bet_option_id, :bet_amount],
      updated_bets: [:id, :bet_option_id, :bet_amount],
      removed_bets: []
    )
  end
end