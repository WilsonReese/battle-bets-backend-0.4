module BetOptions
  module Evaluators
    class PassingEvaluator
      def initialize(game, player_stats)
        @game    = game
        @entries = player_stats

        # 1️⃣ Build a flat array of only the Passing‐group players
        @passing_players = @entries.flat_map do |team_data|
          passing_group = team_data["groups"]
                          .find { |g| g["name"].casecmp("Passing").zero? }
          passing_group ? passing_group.fetch("players", []) : []
        end
      end

      def call
        opts = @game.bet_options.where(bet_flavor: [:player_pass_tds, :player_pass_yds])
        return puts "ℹ️  No passing BetOptions for Game##{@game.id}" if opts.empty?

        puts "\n🏈 Evaluating passing props:"
        opts.each do |opt|
          # 2️⃣ Parse title
          #    "AJ Swann throws over 0.5 passing TDs"
          #    "AJ Swann throws for under 200 yards"
          m = opt.title.match(/\A(.+?) throws(?: for)? (over|under) (\d+(?:\.\d+)?)/i)
          unless m
            puts "⚠️  ##{opt.id}: #{opt.bet_flavor}: cannot parse title=#{opt.title.inspect}"
            next
          end

          player_name = m[1]
          direction   = m[2].downcase
          threshold   = m[3].to_f

          # 3️⃣ Find that player in our Passing‐group array

          # HARD CODE -- UPDATE NEEDED: Add Fuzzy Matching here

          pdata = @passing_players.find { |p| p.dig("player","name") == player_name }
          unless pdata
            puts "⚠️  ##{opt.id}: no stats for player #{player_name}"
            opt.update!(success: false)
            next
          end

          # 4️⃣ Pick the right stat key
          stat_key = opt.player_pass_tds? ? "passing touch downs" : "yards"

          stat = (pdata["statistics"] || []).find { |s|
            s["name"].casecmp(stat_key).zero?
          }
          unless stat
            puts "⚠️  ##{opt.id}: no stat '#{stat_key}' for #{player_name}"
            opt.update!(success: false)
            next
          end

          actual = stat["value"].to_f

          # 5️⃣ Over/Under comparison
          won = if direction == "over"
                  actual > threshold
                else
                  actual < threshold
                end

          opt.update!(success: won)
          result = won ? "✅ win" : "❌ loss"
          puts "  • ##{opt.id} (#{opt.title}): actual=#{actual} vs #{threshold} → #{result}"
        end
      end
    end
  end
end