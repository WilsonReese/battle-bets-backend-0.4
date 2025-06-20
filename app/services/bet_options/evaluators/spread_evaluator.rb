module BetOptions
  module Evaluators
    class SpreadEvaluator
      def initialize(game, entry, home_score, away_score)
        @game        = game
        @entry       = entry
        @home_score  = home_score
        @away_score  = away_score
      end

      def call
        opts = @game.bet_options.where(bet_flavor: [:home_team_spread, :away_team_spread])
        return puts "ℹ️  No spread BetOptions" if opts.empty?

        puts "\n🔀 Evaluating spreads:"
        opts.each do |opt|
          m = opt.title.match(/([+-]?)(\d+(\.\d+)?)/)
          unless m
            puts "⚠️  Skipping ##{opt.id}: can't parse #{opt.title.inspect}"
            next
          end

          sign, pts = (m[1] == "-" ? -1 : +1), m[2].to_f
          if opt.home_team_spread?
            adjusted = @home_score + sign * pts
            winner   = adjusted > @away_score
          else
            adjusted = @away_score + sign * pts
            winner   = adjusted > @home_score
          end

          opt.update!(success: winner)
          result = winner ? "✅ win" : "❌ loss"
          puts "  • ##{opt.id} (#{opt.title}): adjusted=#{adjusted.round(1)} → #{result}"
        end
      end
    end
  end
end