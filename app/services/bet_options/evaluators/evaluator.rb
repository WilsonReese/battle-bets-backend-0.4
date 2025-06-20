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
        api_id = raw_id.start_with?("temp_") ? raw_id.split("_")[1] : raw_id

        # 3️⃣ Find the JSON entry whose "game.id" matches our api_id
        @entry = entries.find do |e|
          e.dig("game", "id").to_s == api_id
        end
        raise "No game_stats entry for Game##{@game.id} (api_sports_io_game_id=#{@game.api_sports_io_game_id})" unless @entry

        events_path = Rails.root.join("lib/data/sample_game/game_events.json")
        raw_events  = JSON.parse(File.read(events_path))
        @events     = raw_events.is_a?(Hash) && raw_events["response"].is_a?(Array) ? raw_events["response"] : Array(raw_events)
      end

      def run
        load_scores!
        puts "ℹ️  Game##{@game.id}: home=#{@home_score}, away=#{@away_score}, total=#{@total_score}"

        SpreadEvaluator.new(@game, @entry, @home_score, @away_score).call
        MoneyLineEvaluator.new(@game, @home_score, @away_score).call
        OverUnderEvaluator.new(@game, @total_score).call
        OvertimeEvaluator.new(@game, @entry).call
        FirstTeamToScoreEvaluator.new(@game, @events).call

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