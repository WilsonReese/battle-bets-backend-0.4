require "json"

module BetOptions
  module Evaluators
    class Evaluator
      def initialize(game_id)
        @game = Game.find(game_id)
        stats_path = Rails.root.join("lib", "data", "sample_game", "game_stats.json")
        raw = JSON.parse(File.read(stats_path))
        @entry = raw.is_a?(Hash) && raw["response"] ? raw["response"].first : raw.first || raw
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