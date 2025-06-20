module BetOptions
  module Evaluators
    class MoneyLineEvaluator
      def initialize(game, home_score, away_score)
        @game       = game
        @home_score = home_score
        @away_score = away_score
      end

      def call
        opts = @game.bet_options.where(bet_flavor: [:home_team_ml, :away_team_ml])
        return puts "ℹ️  No money-line BetOptions" if opts.empty?

        puts "\n🎲 Evaluating money-lines:"
        opts.each do |opt|
          winner = opt.home_team_ml? ? (@home_score > @away_score) : (@away_score > @home_score)
          opt.update!(success: winner)
          side   = opt.home_team_ml? ? "home" : "away"
          result = winner ? "✅ win" : "❌ loss"
          puts "  • ##{opt.id} (#{side}_team_ml): #{result}"
        end
      end
    end
  end
end