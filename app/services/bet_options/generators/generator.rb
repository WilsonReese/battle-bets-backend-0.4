module BetOptions
  module Generators
    class Generator
      def initialize(season_year, week)
        @season = Season.find_by!(year: season_year)
        @week   = week
        @games  = Game.where(season: @season, week: @week)

        @sample_bets       = JSON.parse(File.read(Rails.root.join("lib/data/sample_bet_options.json")))
        @prop_odds_api_data    = JSON.parse(File.read(Rails.root.join("lib/data/prop_bets_odds.json")))
        @prop_api_sports_data     = JSON.parse(File.read(Rails.root.join("lib/data/prop_bets_api_sports.json")))["response"]
      end

      def run
        puts "📊 Generating bet options for Week #{@week} of #{@season.year}: #{@games.count} games"

        @games.each_with_index do |game, idx|
          # 1. Find the exact sample record by matching the JSON "id" to your game.odds_api_game_id
          # I edited sample_bet_options to use a specifc ID.
          sample = @sample_bets.find do |rec|
            rec_id = rec["id"].to_s
            game.odds_api_game_id.to_s == rec_id
          end

          unless sample
            puts "⚠️  [#{idx+1}] No sample_bets entry for Game##{game.id} (odds_api_game_id=#{game.odds_api_game_id})"
            next
          end

          # 2. Grab DK data from that record
          dk = sample["bookmakers"].find { |b| b["key"] == "draftkings" }
          unless dk
            puts "⚠️  [#{idx+1}] Sample record found but no DraftKings market"
            next
          end

          # 3. Build your context and delegate
          context = {
            game:            game,
            draftkings:      dk,
            odds_api_data:   @prop_odds_api_data,
            api_sports_data: @prop_api_sports_data
          }

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