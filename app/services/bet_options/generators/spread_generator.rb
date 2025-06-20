module BetOptions
  module Generators
    class SpreadGenerator
      def initialize(ctx)
        @game       = ctx[:game]
        @draftkings         = ctx[:draftkings]
      end

      def generate
        market = @draftkings.dig("markets")&.find { |m| m["key"] == "spreads" }
        return puts "⚠️  No spreads market for Game##{@game.id}" unless market

        outcomes = market["outcomes"]
        [
          { team: @game.away_team, outcome: outcomes[0], flavor: :away_team_spread },
          { team: @game.home_team, outcome: outcomes[1], flavor: :home_team_spread }
        ].each do |b|
          pt = b[:outcome]["point"]
          formatted = pt.positive? ? "+#{pt}" : pt.to_s

          BetOption.create!(
            title:      "#{b[:team].name} #{formatted}",
            payout:     2.0,
            category:   "spread",
            game:       @game,
            bet_flavor: b[:flavor]
          )
          puts "✅ Spread #{b[:flavor]} for #{b[:team].name} #{formatted}"
        end
      end
    end
  end
end