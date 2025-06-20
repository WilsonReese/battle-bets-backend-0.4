module BetOptions
  module Evaluators
    class OverUnderEvaluator
      def initialize(game, total_score)
        @game        = game
        @total_score = total_score
      end

      def call
        opts = @game.bet_options.where(bet_flavor: [:over, :under])
        return puts "ℹ️  No over/under BetOptions" if opts.empty?

        puts "\n📊 Evaluating over/under:"
        opts.each do |opt|
          m = opt.title.match(/(\d+(\.\d+)?)/)
          unless m
            puts "⚠️  Skipping ##{opt.id}: can't parse #{opt.title.inspect}"
            next
          end

          threshold = m[1].to_f
          winner   = opt.over? ? (@total_score > threshold) : (@total_score < threshold)
          opt.update!(success: winner)
          side   = opt.over? ? "OVER" : "UNDER"
          result = winner ? "✅ win" : "❌ loss"
          puts "  • ##{opt.id} (#{side} #{threshold}): #{result}"
        end
      end
    end
  end
end