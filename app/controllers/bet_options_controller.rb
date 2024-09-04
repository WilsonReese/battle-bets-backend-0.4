class BetOptionsController < ApplicationController
    before_action :set_game

    def index
      @bet_options = @game.bet_options
      render json: @bet_options
    end
  
    private
  
    def set_game
      @game = Game.find(params[:game_id])
    end
end
