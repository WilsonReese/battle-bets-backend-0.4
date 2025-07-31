require "json"
require "api_sports_client"

module BetOptions
  module Evaluators
    class Evaluator
      def initialize(game_id)
        @game = Game.find(game_id)

        # ========== LOAD GAME STATS ========== #
        # normalize the ID (strip any "temp_...")
        raw_id = @game.api_sports_io_game_id.to_s
        api_id = raw_id.start_with?("temp_") ? raw_id.split("_")[1] : raw_id

        # hit /games?id=#{api_id}
        payload = ApiSportsClient.games(id: api_id)
        entries = payload.fetch("response", [])

        # find the one entry matching our game
        @entry = entries.find { |e|
          e.dig("game","id").to_s == api_id
        }
        unless @entry
          raise "No game_stats entry for Game##{@game.id} (api_sports_io_game_id=#{@game.api_sports_io_game_id})"
        end

        # ========== LOAD GAME EVENTS ========== #

        # NEED TO DO This is the API Sports IO game/events end point (for a specific game)
        events_path = Rails.root.join("lib/data/sample_game/game_events.json")
        raw_events  = JSON.parse(File.read(events_path))
        @events     = raw_events.is_a?(Hash) && raw_events["response"].is_a?(Array) ? raw_events["response"] : Array(raw_events)

        # ========== LOAD PLAYER STATS ========== #
        # NEED TO DO This is the API Sports IO game/statistics/players end point (for a specific game)
        players_path = Rails.root.join("lib/data/sample_game/player_stats.json")
        raw_players  = JSON.parse(File.read(players_path))
        @player_stats = if raw_players.is_a?(Hash) && raw_players["response"].is_a?(Array)
                          raw_players["response"]
                        else
                          Array(raw_players)
                        end
      end

      def run
        load_scores!
        puts "ℹ️  Game##{@game.id}: home=#{@home_score}, away=#{@away_score}, total=#{@total_score}"

        SpreadEvaluator.new(@game, @entry, @home_score, @away_score).call
        MoneyLineEvaluator.new(@game, @home_score, @away_score).call
        OverUnderEvaluator.new(@game, @total_score).call
        OvertimeEvaluator.new(@game, @entry).call
        FirstTeamToScoreEvaluator.new(@game, @events).call
        PassingEvaluator.new(@game, @player_stats).call
        ReceivingEvaluator.new(@game, @player_stats).call
        RushingEvaluator.new(@game, @player_stats).call
        SacksEvaluator.new(@game, @player_stats).call

        puts "\n🏁 Done evaluating all BetOptions for Game##{@game.id}."
      end

      private

      def load_scores!
        scores     = @entry.fetch("scores", {})
        @home_score  = scores.dig("home", "total").to_i
        @away_score  = scores.dig("away", "total").to_i
        @total_score = @home_score + @away_score
      end
    end
  end
end