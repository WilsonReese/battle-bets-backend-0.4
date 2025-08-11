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

        outcomes = Array(market["outcomes"])
        return puts "⚠️  No spread outcomes for Game##{@game.id}" if outcomes.empty?

        by_name = outcomes.index_by { |o| norm(o["name"]) }

        away_key = norm(@game.away_team.long_name_odds_api)
        home_key = norm(@game.home_team.long_name_odds_api)

        away_outcome = by_name[away_key]
        home_outcome = by_name[home_key]

        # [
        #   { team: @game.away_team, outcome: outcomes[0], flavor: :away_team_spread },
        #   { team: @game.home_team, outcome: outcomes[1], flavor: :home_team_spread }
        # ].each do |b|
        #   pt = b[:outcome]["point"]
        #   formatted = pt.positive? ? "+#{pt}" : pt.to_s

        #   BetOption.create!(
        #     title:      "#{b[:team].name} #{formatted}",
        #     payout:     2.0,
        #     category:   "spread",
        #     game:       @game,
        #     bet_flavor: b[:flavor]
        #   )
        #   puts "✅ Spread #{b[:flavor]} for #{b[:team].name} #{formatted}"
        # end
        create_spread_option(@game.away_team, away_outcome, :away_team_spread)
        create_spread_option(@game.home_team, home_outcome, :home_team_spread)
      end
      
      private

      def norm(s)
        s.to_s.strip.downcase
      end

      def create_spread_option(team, outcome, flavor)
        pt = outcome["point"].to_f

        formatted =
          if pt.zero?
            "EVEN"
          else
            # If it's a whole number (other than zero), add .5 to avoid pushes
            if pt == pt.to_i
              pt = pt.positive? ? pt + 0.5 : pt - 0.5
            end
            pt.positive? ? "+#{pt}" : pt.to_s
          end

        BetOption.create!(
          title:      "#{team.name} #{formatted}",
          payout:     2.0, # keep your payout logic
          category:   "spread",
          game:       @game,
          bet_flavor: flavor
        )
        puts "✅ Spread #{flavor} for #{team.name} #{formatted}"
      end
    end
  end
end