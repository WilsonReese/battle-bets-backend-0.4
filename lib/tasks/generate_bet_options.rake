namespace :bet_options do
  desc "Generate sample spread bet options for a given season and week"
  task :generate_spreads, [:season_year, :week] => :environment do |t, args|
    require "json"

    season_year = args[:season_year].to_i
    week = args[:week].to_i

    if season_year <= 0 || week <= 0
      puts "❌ Please provide valid season_year and week (e.g., rake bet_options:generate_spreads[2023,1])"
      next
    end

    season = Season.find_by(year: season_year)

    if season.nil?
      puts "❌ No season found for year #{season_year}"
      next
    end

    file_path = Rails.root.join("lib", "data", "sample_bet_options.json")
    data = JSON.parse(File.read(file_path))

    games = Game.where(season_id: season.id, week: week)
    puts "📊 Creating spread bet options for #{games.count} games in Week #{week} of #{season_year}..."

    games.each_with_index do |game, i|
      record = data.first # using the first record every time for sample data
      draftkings = record["bookmakers"].find { |b| b["key"] == "draftkings" }
      spreads_market = draftkings&.dig("markets")&.find { |m| m["key"] == "spreads" }

      unless spreads_market
        puts "⚠️ No spread market for game #{i + 1}"
        next
      end

      outcomes = spreads_market["outcomes"]
      away_team = Team.find(game.away_team_id)
      home_team = Team.find(game.home_team_id)

      [
        # assumes away team is always first in outcomes, home team second
        { team: away_team, outcome: outcomes[0], flavor: "away_team_spread" }, 
        { team: home_team, outcome: outcomes[1], flavor: "home_team_spread" }
      ].each do |bet|
        point = bet[:outcome]["point"]
        formatted_point = point.positive? ? "+#{point}" : point.to_s

        BetOption.create!(
          title: "#{bet[:team].name} #{formatted_point}",
          payout: 2.0,
          category: "spread",
          game_id: game.id,
          bet_flavor: bet[:flavor]
        )

        puts "✅ Created #{bet[:flavor]} for #{bet[:team].name} #{formatted_point}"
      end
    end

    puts "🏁 Done generating sample spread bet options"
  end
end