module BetOptions
  module Evaluators
    class RushingEvaluator
      def initialize(game, player_stats)
        @game    = game
        @entries = player_stats

        # 1️⃣ Flatten only the Rushing‐group players
        @rushing_players = @entries.flat_map do |team_data|
          rush_group = team_data["groups"]
                          .find { |g| g["name"].casecmp("Rushing").zero? }
          rush_group ? rush_group.fetch("players", []) : []
        end
      end

      def call
        #  only the three flavors we care about
        flavors = %i[player_rush_attempts player_rush_tds player_rush_yds]
        opts = @game.bet_options.where(bet_flavor: flavors)
        return puts "ℹ️  No rushing BetOptions for Game##{@game.id}" if opts.empty?

        puts "\n🏃 Evaluating rushing props:"
        opts.each do |opt|
          # 2️⃣ Parse title: "AJ Swann has over 5 rush attempts", 
          #               "... has under 1 rushing TDs", 
          #               "... has over 80 rushing yards"
          m = opt.title.match(/\A(.+?) has (over|under) (\d+(?:\.\d+)?)/i)
          unless m
            puts "⚠️  ##{opt.id}: cannot parse title=#{opt.title.inspect}"
            next
          end

          player_name = m[1]
          direction   = m[2].downcase
          threshold   = m[3].to_f

          # 3️⃣ Find that player
          pdata = @rushing_players.find { |p| p.dig("player","name") == player_name }
          unless pdata
            puts "⚠️  ##{opt.id}: no rushing stats for player #{player_name}"
            opt.update!(success: false)
            next
          end

          # 4️⃣ Pick stat key
          stat_key = case opt.bet_flavor.to_sym
                     when :player_rush_attempts then "total rushes"
                     when :player_rush_tds      then "rushing touch downs"
                     when :player_rush_yds      then "yards"
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