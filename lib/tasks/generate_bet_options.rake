namespace :bet_options do
  desc "Generate sample spread and moneyline bet options for a given season and week"
  task :generate, [:season_year, :week] => :environment do |t, args|
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
    puts "📊 Creating spread and moneyline bet options for #{games.count} games in Week #{week} of #{season_year}..."

    games.each_with_index do |game, i|
      record = data.first # Use the same record for all games (development sample data)
      draftkings = record["bookmakers"].find { |b| b["key"] == "draftkings" }

      if draftkings.nil?
        puts "⚠️ No DraftKings data for game #{i + 1}"
        next
      end

      spreads_market = draftkings.dig("markets")&.find { |m| m["key"] == "spreads" }
      h2h_market = draftkings.dig("markets")&.find { |m| m["key"] == "h2h" }

      away_team = Team.find(game.away_team_id)
      home_team = Team.find(game.home_team_id)

      # === Spread Bet Options ===
      if spreads_market
        outcomes = spreads_market["outcomes"]

        [
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
      else
        puts "⚠️ No spread market for game #{i + 1}"
      end

      # === Moneyline Bet Options ===
      if h2h_market
        outcomes = h2h_market["outcomes"]
        if outcomes.size >= 2
          home_price = outcomes[1]["price"]
          away_price = outcomes[0]["price"]
          home_odds, away_odds = fair_decimal_odds(home_price, away_price)

          BetOption.create!(
            title: "#{away_team.name} wins",
            payout: away_odds,
            category: "money_line",
            game_id: game.id,
            bet_flavor: "away_team_ml"
          )
          puts "✅ Created away_team_ml for #{away_team.name} (x#{away_odds})"

          BetOption.create!(
            title: "#{home_team.name} wins",
            payout: home_odds,
            category: "money_line",
            game_id: game.id,
            bet_flavor: "home_team_ml"
          )
          puts "✅ Created home_team_ml for #{home_team.name} (x#{home_odds})"
        else
          puts "⚠️ Not enough outcomes for moneyline in game #{i + 1}"
        end
      else
        puts "⚠️ No moneyline market for game #{i + 1}"
      end
    end

    puts "🏁 Done generating sample spread and moneyline bet options"
  end
end

# === Odds Conversion Helpers ===

def implied_probability(american_odds)
  if american_odds > 0
    100.0 / (american_odds + 100.0)
  else
    american_odds.abs / (american_odds.abs + 100.0)
  end
end

def fair_decimal_odds(odds1, odds2)
  p1 = implied_probability(odds1)
  p2 = implied_probability(odds2)
  total = p1 + p2

  [
    (1.0 / (p1 / total)).round(1),
    (1.0 / (p2 / total)).round(1)
  ]
end