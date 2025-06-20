module BetOptions
  module Evaluators
    class ReceivingEvaluator
      def initialize(game, player_stats)
        @game    = game
        @entries = player_stats

        # 1️⃣ Flatten only the Receiving‐group players
        @receiving_players = @entries.flat_map do |team_data|
          recv_group = team_data["groups"]
                         .find { |g| g["name"].casecmp("Receiving").zero? }
          recv_group ? recv_group.fetch("players", []) : []
        end
      end

      def call
        # All three flavors
        flavors = %i[player_receptions player_reception_tds player_reception_yds]
        opts = @game.bet_options.where(bet_flavor: flavors)
        return puts "ℹ️  No receiving BetOptions for Game##{@game.id}" if opts.empty?

        puts "\n🤲 Evaluating receiving props:"
        opts.each do |opt|
          # 2️⃣ Parse title: "Jayden McGowan has over 3 receptions", "... receiving TDs", "... yards"
          m = opt.title.match(/\A(.+?) has (over|under) (\d+(?:\.\d+)?)/i)
          unless m
            puts "⚠️  ##{opt.id}: cannot parse title=#{opt.title.inspect}"
            next
          end

          player_name = m[1]
          direction   = m[2].downcase
          threshold   = m[3].to_f

          # 3️⃣ Find that player
          pdata = @receiving_players.find { |p| p.dig("player","name") == player_name }
          unless pdata
            puts "⚠️  ##{opt.id}: no stats for player #{player_name}"
            opt.update!(success: false)
            next
          end

          # 4️⃣ Choose stat key
          stat_key = case opt.bet_flavor.to_sym
                     when :player_receptions
                       "total receptions"
                     when :player_reception_tds
                       "receiving touch downs"
                     when :player_reception_yds
                       "yards"
                     end

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