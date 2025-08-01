# app/controllers/api/v1/api_sports_controller.rb
module Api
  module V1
    class ApiSportsController < ApplicationController
      # whitelist only the params you actually want to forward
      ALLOWED_GAME_PARAMS = %i[id league season date team page per_page]

      # GET /api/v1/api_sports/games
      def games
        # permit only our allowed keys
        query = params.permit(ALLOWED_GAME_PARAMS).to_h

        # call our service
        payload = ApiSportsClient.games(query)

        # return just the 'response' array
        render json: payload['response']
      rescue => e
        render json: { error: e.message }, status: :bad_gateway
      end

      # GET /api/v1/api_sports/game_statistics/teams?id=13838
      def team_statistics
        # only allow the game ID param
        query = params.permit(:id).to_h

        # proxy the call
        payload = ApiSportsClient.team_statistics(query)

        # render just the `response` array
        render json: payload['response']
      rescue => e
        render json: { error: e.message }, status: :bad_gateway
      end

      # GET /api/v1/api_sports/game_statistics/players?id=13838
      def player_statistics
        # only allow the game ID param
        query = params.permit(:id).to_h

        # proxy the call
        payload = ApiSportsClient.player_statistics(query)

        # render just the `response` array
        render json: payload['response']
      rescue => e
        render json: { error: e.message }, status: :bad_gateway
      end

      # you can add more actions here:
      # def teams
      #   query = params.permit(:league, :page).to_h
      #   payload = ApiSportsClient.teams(query)
      #   render json: payload['response']
      # end
    end
  end
end