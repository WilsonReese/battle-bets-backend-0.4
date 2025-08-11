module BetOptions
  module Generators
    class MoneyLineGenerator
      include Helpers::OddsHelper

      def initialize(ctx)
        @game = ctx[:game]
        @draftkings   = ctx[:draftkings]
      end

      def generate
        market = @draftkings.dig("markets")&.find { |m| m["key"] == "h2h" }
        return puts "⚠️  No ML market for Game##{@game.id}" unless market

        outcomes = Array(market["outcomes"])
        return puts "⚠️  Not enough ML outcomes" if outcomes.size < 2

        by_name = outcomes.index_by { |o| norm(o["name"]) }

        away_key = norm(@game.away_team.long_name_odds_api)
        home_key = norm(@game.home_team.long_name_odds_api)

        away_outcome = by_name[away_key]
        home_outcome = by_name[home_key]

        away_price = away_outcome["price"]
        home_price = home_outcome["price"]

        # away_price, home_price = out[0]["price"], out[1]["price"]
        home_odds, away_odds   = fair_decimal_odds(home_price, away_price)

        BetOption.create!(
          title:      "#{@game.away_team.name} wins",
          payout:     away_odds,
          category:   "money_line",
          game:       @game,
          bet_flavor: :away_team_ml
        )
        puts "✅ away_team_ml (x#{away_odds})"

        BetOption.create!(
          title:      "#{@game.home_team.name} wins",
          payout:     home_odds,
          category:   "money_line",
          game:       @game,
          bet_flavor: :home_team_ml
        )
        puts "✅ home_team_ml (x#{home_odds})"
      end

      private

      def norm(s)
        s.to_s.strip.downcase
      end      
    end
  end
end