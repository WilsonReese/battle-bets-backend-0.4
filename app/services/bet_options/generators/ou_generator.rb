module BetOptions
  module Generators
    class OuGenerator
      def initialize(ctx)
        @game = ctx[:game]
        @dk   = ctx[:draftkings]
      end

      def generate
        market = @dk.dig("markets")&.find { |m| m["key"] == "totals" }
        return puts "⚠️  No totals market for Game##{@game.id}" unless market

        outcomes = market["outcomes"]
        [ {label: "Over", flavor: :over}, {label: "Under", flavor: :under} ]
          .each_with_index do |b, i|
            pt = outcomes[i]["point"]
            BetOption.create!(
              title:      "#{b[:label]} #{pt} Points",
              payout:     2.0,
              category:   "ou",
              game:       @game,
              bet_flavor: b[:flavor]
            )
            puts "✅ #{b[:flavor]} #{pt}"
          end
      end
    end
  end
end