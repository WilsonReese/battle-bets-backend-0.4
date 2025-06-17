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
		odds_api_data = JSON.parse(File.read(Rails.root.join("lib", "data", "prop_bets_odds.json")))
		api_sports_io_data = JSON.parse(File.read(Rails.root.join("lib", "data", "prop_bets_api_sports.json")))["response"]	

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
			totals_market  = draftkings.dig("markets")&.find { |m| m["key"] == "totals" }


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

			# === Over/Under Bet Options ===
      if totals_market
        outcomes = totals_market["outcomes"]

        [
          { label: "Over",  flavor: "over"  },
          { label: "Under", flavor: "under" }
        ].each_with_index do |bet, idx|
          point = outcomes[idx]["point"]
          BetOption.create!(
            title: "#{bet[:label]} #{point} Points",
            payout: 2.0,
            category: "ou",
            game_id: game.id,
            bet_flavor: bet[:flavor]
          )

          puts "✅ Created #{bet[:flavor]} (#{bet[:label]} #{point})"
        end
      else
        puts "⚠️ No totals (OU) market for game #{i + 1}"
      end
    end

    puts "🏁 Done generating sample spread and moneyline bet options"
  end

	# Prop Bets Task

	desc "Generate sample prop bet options for a given season and week"
  task :generate_props, [:season_year, :week] => :environment do |t, args|
    require "json"

    season_year = args[:season_year].to_i
    week = args[:week].to_i

    if season_year <= 0 || week <= 0
      puts "❌ Please provide valid season_year and week (e.g., rake bet_options:generate_props[2023,1])"
      next
    end

    season = Season.find_by(year: season_year)
    if season.nil?
      puts "❌ No season found for year #{season_year}"
      next
    end

    odds_path = Rails.root.join("lib", "data", "prop_bets_odds.json")
    api_path = Rails.root.join("lib", "data", "prop_bets_api_sports.json")
    odds_data = JSON.parse(File.read(odds_path))
    api_data = JSON.parse(File.read(api_path))["response"]

    games = Game.where(season_id: season.id, week: week)
    puts "🎯 Generating 4 prop bets per game for #{games.count} games..."

    games.each_with_index do |game, i|
      away_team = Team.find(game.away_team_id)
      home_team = Team.find(game.home_team_id)

      puts "📌 Game #{i + 1}: #{away_team.name} vs #{home_team.name}"

      # --- Odds API Props (2 random props) ---
      odds_markets = odds_data["bookmakers"].first["markets"]
      available_props = odds_markets.select { |m| m["key"].start_with?("player_") }
      available_props.sample(2).each do |market|
        outcome = market["outcomes"].sample
        next unless outcome

        description = outcome["description"]
        name = outcome["name"]
        point = outcome["point"]
        price = outcome["price"]

        payout = fair_decimal_odds(price, -100).first

        BetOption.create!(
          title: "#{description}: #{name} #{point}",
          payout: payout,
          category: "prop",
          game_id: game.id,
          bet_flavor: market["key"]
        )
        puts "✅ Odds prop: #{description} #{name} #{point} (#{market["key"]})"
      end

      # --- API Sports IO Props (2 fixed IDs: 12 and 52) ---
      bets = api_data.first["bookmakers"].first["bets"]
      bets.select { |b| [12, 52].include?(b["id"]) }.each do |bet|
        bet["values"].sample(1).each do |val|
          BetOption.create!(
            title: "#{bet["name"]}: #{val["value"]}",
            payout: val["odd"].to_f.round(1),
            category: "prop",
            game_id: game.id,
            bet_flavor: bet["name"].parameterize.underscore
          )
          puts "✅ API Sports prop: #{bet["name"]} - #{val["value"]}"
        end
      end
    end

    puts "🏁 Done generating sample prop bets"
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


# === Prop Bets ===
PROP_BETS_REGISTRY = {
  overtime: {
    label: "Will the game go to Overtime?",
    source: :api_sports_io,
    id: 12
  },
  first_team_to_score: {
    label: "First Team to Score",
    source: :api_sports_io,
    id: 52
  },
  multi_td_scorer: {
    label: "Multi Touchdown Scorer",
    source: :api_sports_io,
    id: 50
  }, # did not include in sample data
  btts: {
    label: "Both Teams to Score",
    source: :odds_api,
    key: "btts"
  }, # did not include in sample data
  player_pass_tds: { label: "Player Passing TDs", source: :odds_api, key: "player_pass_tds" },
  player_pass_yds: { label: "Player Passing Yards", source: :odds_api, key: "player_pass_yds" },
  player_receptions: { label: "Player Receptions", source: :odds_api, key: "player_receptions" },
	player_reception_tds: { label: "Player Receiving TDs", source: :odds_api, key: "player_reception_tds" },
	player_reception_yds: { label: "Player Receiving Yards", source: :odds_api, key: "player_reception_yds" },
	player_rush_attempts: { label: "Player Rush Attempts", source: :odds_api, key: "player_rush_attempts" },
	player_rush_longest: { label: "Player Longest Rush", source: :odds_api, key: "player_rush_longest" }, # did not include in sample data
	player_rush_tds: { label: "Player Rushing TDs", source: :odds_api, key: "player_rush_tds" },
	player_rush_yds: { label: "Player Rushing Yards", source: :odds_api, key: "player_rush_yds" },
	player_sacks: { label: "Player Sacks", source: :odds_api, key: "player_sacks" },
  player_anytime_td: { label: "Anytime TD Scorer", source: :odds_api, key: "player_anytime_td" }, # did not include in sample data
  player_1st_td: { label: "First TD Scorer", source: :odds_api, key: "player_1st_td" }, # did not include in sample data
  player_last_td: { label: "Last TD Scorer", source: :odds_api, key: "player_last_td" } # did not include in sample data
}
