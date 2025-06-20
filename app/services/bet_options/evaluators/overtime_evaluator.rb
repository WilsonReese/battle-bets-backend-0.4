module BetOptions
  module Evaluators
    class OvertimeEvaluator
      def initialize(game, entry)
        @game  = game
        @entry = entry
      end

      def call
        opts = @game.bet_options.where(bet_flavor: :overtime)
        return puts "ℹ️  No overtime BetOptions for Game##{@game.id}" if opts.empty?

        # Pull the raw OT values from your JSON
        scores   = @entry.fetch("scores", {})
        ot_home  = scores.dig("home", "overtime")
        ot_away  = scores.dig("away", "overtime")
        happened = ot_home != nil || ot_away != nil

        puts "\n⏱️ Evaluating overtime: happened=#{happened}"

        opts.each do |opt|
          opt.update!(success: happened)
          result = happened ? "✅ yes" : "❌ no"
          puts "  • ##{opt.id} (overtime): #{result}"
        end
      end
    end
  end
end