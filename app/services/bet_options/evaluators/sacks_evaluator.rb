module BetOptions
  module Evaluators
    class SacksEvaluator
      def initialize(game, player_stats)
        @game    = game
        @entries = player_stats

        # 1️⃣ Flatten only the Defensive‐group players
        @defensive_players = @entries.flat_map do |team_data|
          def_group = team_data["groups"]
                         .find { |g| g["name"].casecmp("Defensive").zero? }
          def_group ? def_group.fetch("players", []) : []
        end
      end

      def call
        opts = @game.bet_options.where(bet_flavor: :player_sacks)
        return puts "ℹ️  No sack BetOptions for Game##{@game.id}" if opts.empty?

        puts "\n🛡️ Evaluating sacks props:"
        opts.each do |opt|
          # 2️⃣ Parse title: "AJ Swann has over 2 sacks"
          m = opt.title.match(/\A(.+?) has (over|under) (\d+(?:\.\d+)?)/i)
          unless m
            puts "⚠️  ##{opt.id}: cannot parse title=#{opt.title.inspect}"
            next
          end

          player_name = m[1]
          direction   = m[2].downcase
          threshold   = m[3].to_f

          # 3️⃣ Find that player
          pdata = @defensive_players.find { |p| p.dig("player","name") == player_name }
          unless pdata
            puts "⚠️  ##{opt.id}: no defensive stats for player #{player_name}"
            opt.update!(success: false)
            next
          end

          # 4️⃣ Pick the right stat key
          stat_key = "sacks"
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
          won = direction == "over" ? (actual > threshold) : (actual < threshold)
          opt.update!(success: won)

          result = won ? "✅ win" : "❌ loss"
          puts "  • ##{opt.id} (#{opt.title}): actual=#{actual} vs #{threshold} → #{result}"
        end
      end
    end
  end
end