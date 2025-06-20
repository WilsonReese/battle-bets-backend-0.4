module BetOptions
  module Generators
    class PropGenerator
      include Helpers::OddsHelper

      def initialize(ctx)
        @game           = ctx[:game]
        @odds_api_data  = ctx[:odds_api_data]
        @api_sports_data = ctx[:api_sports_data]
      end

      def generate
        registry = Helpers::PropBetsRegistry

        valid = BetOption.bet_flavors.keys.select { |f| PROP_BETS_REGISTRY.key?(f.to_sym) }
        chosen = valid.sample(4)
        chosen.each do |flavor|
          cfg = PROP_BETS_REGISTRY[flavor.to_sym]
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
          market = @odds_api_data.first["bookmakers"].first["markets"]
                     .find { |m| m["key"] == cfg[:key] }
          out    = market["outcomes"].sample
          title  = cfg[:title_builder]&.call(outcome: out)
          payout = (1.0 / implied_probability(out["price"])).round(1)
          [title, payout]

        when :api_sports_io
          bet   = @api_sports_data.first["bookmakers"].first["bets"]
                    .find { |b| b["id"] == cfg[:id] }
          vals  = bet["values"]
          val   = if cfg[:title_builder] && cfg[:id] == 12 # <-- if overtime
                    vals.find { |v| v["value"].casecmp("yes").zero? }
                  else
                    vals.sample
                  end
          title  = cfg[:title_builder]&.call(value: val,
                                            home_team: @game.home_team,
                                            away_team: @game.away_team)
          payout = val["odd"].to_f.round(1)
          [title, payout]
        end
      end
    end
  end
end