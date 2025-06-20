module BetOptions
  module Generators
    class Generator
      def initialize(season_year, week)
        @season = Season.find_by!(year: season_year)
        @week   = week
        @games  = Game.where(season: @season, week: @week)

        @sample_bets       = JSON.parse(File.read(Rails.root.join("lib/data/sample_bet_options.json")))
        @prop_odds_data    = JSON.parse(File.read(Rails.root.join("lib/data/prop_bets_odds.json")))
        @prop_api_data     = JSON.parse(File.read(Rails.root.join("lib/data/prop_bets_api_sports.json")))["response"]
      end

      def run
        puts "📊 Generating bet options for Week #{@week} of #{@season.year}: #{@games.count} games"
        @games.each_with_index do |game, idx|
          context = {
            game:            game,
            draftkings:      @sample_bets.first["bookmakers"].find { |b| b["key"] == "draftkings" },
            odds_api_data:   @prop_odds_data,
            api_sports_data: @prop_api_data
          }

          if context[:draftkings].nil?
            puts "⚠️  No DraftKings entry for game #{idx+1}; skipping"
            next
          end

          SpreadGenerator.new(context).generate
          MoneyLineGenerator.new(context).generate
          OuGenerator.new(context).generate
          PropGenerator.new(context).generate
        end

        puts "🏁 Done."
      end
    end
  end
end