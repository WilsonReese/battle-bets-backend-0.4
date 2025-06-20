require "json"

module BetOptions
  module Evaluators
    class Evaluator
      def initialize(game_id)
        @game = Game.find(game_id)

        # 1️⃣ Load the raw JSON (either a Hash with "response" or an Array)
        stats_path = Rails.root.join("lib", "data", "sample_game", "game_stats.json")
        raw        = JSON.parse(File.read(stats_path))
        entries    = raw.is_a?(Hash) && raw["response"].is_a?(Array) ? raw["response"] : Array(raw)

        # 2️⃣ Clean up any temp IDs, e.g. "temp_9401_475" → "9401"
        raw_id = @game.api_sports_io_game_id.to_s
        api_id = if raw_id.start_with?("temp_")
                   raw_id.split("_")[1]
                 else
                   raw_id
                 end

        # 3️⃣ Find the JSON entry whose "game.id" matches our api_id
        @entry = entries.find do |e|
          e.dig("game", "id").to_s == api_id
        end
        raise "No game_stats entry for Game##{@game.id} (api_sports_io_game_id=#{@game.api_sports_io_game_id})" unless @entry
      end

      def run
        load_scores!
        puts "ℹ️  Game##{@game.id}: home=#{@home_score}, away=#{@away_score}, total=#{@total_score}"

        SpreadEvaluator.new(@game, @entry, @home_score, @away_score).call
        MoneyLineEvaluator.new(@game, @home_score, @away_score).call
        OverUnderEvaluator.new(@game, @total_score).call

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