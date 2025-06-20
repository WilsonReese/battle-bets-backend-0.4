module BetOptions
  module Generators
    class PropGenerator
      include Helpers::OddsHelper

      def initialize(ctx)
        @game             = ctx[:game]
        @odds_api_data    = ctx[:odds_api_data]    # Array of odds-api entries
        @api_sports_data  = ctx[:api_sports_data]  # Array of api-sports_io entries
      end

      def generate
        registry = Helpers::PropBetsRegistry
        valid    = BetOption.bet_flavors.keys.select { |f| registry.key?(f.to_sym) }
        chosen   = valid.sample(4)

        chosen.each do |flavor|
          cfg = registry[flavor.to_sym]
          begin
            title, payout = build_prop(cfg)
            next if title.blank?

            BetOption.create!(
              title:      title,
              payout:     payout,
              category:   "prop",
              game:       @game,
              bet_flavor: flavor
            )
            puts "✅ #{flavor} → #{title}"
          rescue => e
            puts "⚠️ Failed #{flavor}: #{e.message}"
          end
        end
      end

      private

      def build_prop(cfg)
        case cfg[:source]
        when :odds_api
          # 1️⃣ Find the exact odds-api entry by your stored odds_api_game_id
          # In prop_bet_odds, I changed the game id to match a game
          entry = @odds_api_data.find { |e|
            e["id"].to_s == @game.odds_api_game_id.to_s
          }
          raise "No odds_api_data for game #{ @game.id } (#{ @game.odds_api_game_id })" unless entry

          # 2️⃣ Drill into that entry’s DraftKings market
          dk_market = entry.dig("bookmakers")
                         &.find { |b| b["key"] == "draftkings" }
                         &.dig("markets")
                         &.find { |m| m["key"] == cfg[:key] }
          raise "Market #{cfg[:key]} not found in odds_api_data for game #{ @game.id }" unless dk_market

          outcome = dk_market["outcomes"].sample
          title   = cfg[:title_builder]&.call(outcome: outcome)
          payout  = (1.0 / implied_probability(outcome["price"])).round(1)
          [title, payout]

        when :api_sports_io
          # 1️⃣ Find the exact api-sports_io entry by your stored api_sports_io_game_id
          # In prop_bets_api_sports, I changed the game id to match the ID that I care about

          raw_id = @game.api_sports_io_game_id.to_s

          # 1️⃣ Extract the real numeric ID if it’s in "temp_9401_475" form
          api_id = if raw_id.start_with?("temp_")
                     # split on "_" and take the middle element
                     parts = raw_id.split("_")
                     parts[1] # => "9401"
                   else
                     raw_id
                   end
          entry = @api_sports_data.find { |e|
            e.dig("game", "id").to_s == api_id # I use api_id because I have the temporary ids saved during development
          }
          raise "No api_sports_data for game #{ @game.id } (tried api_id=#{api_id})" unless entry

          # 2️⃣ Drill into that entry’s bets
          bets = entry.dig("bookmakers", 0, "bets")
          bet  = bets.find { |b| b["id"].to_i == cfg[:id].to_i }
          raise "Bet #{cfg[:id]} not found in api_sports_data for game #{ @game.id }" unless bet

          values = bet["values"]
          val    = if cfg[:title_builder] && cfg[:id].to_i == 12
                     # overtime: pick the “Yes” value if present
                     values.find { |v| v["value"].casecmp("yes").zero? }
                   else
                     values.sample
                   end
          raise "No values for bet #{cfg[:id]} in game #{ @game.id }" unless val

          title  = cfg[:title_builder]&.call(
                     value:     val,
                     home_team: @game.home_team,
                     away_team: @game.away_team
                   )
          payout = val["odd"].to_f.round(1)
          [title, payout]
        end
      end
    end
  end
end