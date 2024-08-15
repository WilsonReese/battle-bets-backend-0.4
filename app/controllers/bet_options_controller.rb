class BetOptionsController < ApplicationController
    def index
        @bet_options = BetOption.all
        render json: @bet_options
    end
end
