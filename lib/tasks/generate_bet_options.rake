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

	desc "Generate 4 prop bets per game for a given season and week"
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

      valid_flavors = BetOption.bet_flavors.keys.select { |flavor| PROP_BETS_REGISTRY.key?(flavor.to_sym) }
      selected_flavors = valid_flavors.sample(4)

      selected_flavors.each do |flavor|
        config = PROP_BETS_REGISTRY[flavor.to_sym]

				begin
					case config[:source]
					when :odds_api
						market = odds_data.first["bookmakers"].first["markets"].find { |m| m["key"] == config[:key] }
						raise "Market #{config[:key]} not found" if market.nil?

						outcomes = market["outcomes"]
						raise "Expected outcomes to be an Array" unless outcomes.is_a?(Array)

						outcome = outcomes.sample
						builder = config[:title_builder]
						title = builder&.call(outcome: outcome)
						# Extract payout from American odds
						price = outcome["price"]
						payout = (1.0 / implied_probability(price)).round(1)

					when :api_sports_io
						bets = api_data.first["bookmakers"].first["bets"]
						bet = bets.find { |b| b["id"] == config[:id] }
						  # For overtime: only pick the "Yes" value
  					value = if flavor.to_sym == :overtime
										bet["values"].find { |v| v["value"].downcase == "yes" }
										else
											bet["values"].sample
										end

  next if value.nil? # skip if "Yes" isn't found
						builder = config[:title_builder]
						title = builder&.call(value: value, home_team: home_team, away_team: away_team)
						payout = value["odd"].to_f.round(1)
					end

					next if title.nil?

					BetOption.create!(
						title: title,
						payout: payout,
						category: "prop",
						game_id: game.id,
						bet_flavor: flavor
					)
					puts "✅ Created #{flavor} prop: #{title}"

				rescue => e
					puts "⚠️ Failed to create #{flavor} prop bet: #{e.message}"
				end
      end
    end

    puts "🏁 Done generating prop bets"
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
    source: :api_sports_io,
    id: 12,
    title_builder: ->(value:, home_team:, away_team:) {
      return nil if value["value"].downcase == "no"
      "Game goes to OT"
    }
  },
  first_team_to_score: {
    source: :api_sports_io,
    id: 52,
    title_builder: ->(value:, home_team:, away_team:) {
      team = value["value"].downcase == "home" ? home_team.name : away_team.name
      "#{team} scores first"
    }
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
  player_pass_tds: {
    source: :odds_api,
    key: "player_pass_tds",
    title_builder: ->(outcome:) {
      "#{outcome['description']} throws #{outcome['name'].downcase} #{outcome['point']} passing TDs"
    }
  },
  player_pass_yds: {
    source: :odds_api,
    key: "player_pass_yds",
    title_builder: ->(outcome:) {
      "#{outcome['description']} throws for #{outcome['name'].downcase} #{outcome['point']} yards"
    }
  },
  player_receptions: {
    source: :odds_api,
    key: "player_receptions",
    title_builder: ->(outcome:) {
      "#{outcome['description']} has #{outcome['name'].downcase} #{outcome['point']} receptions"
    }
  },
  player_reception_tds: {
    source: :odds_api,
    key: "player_reception_tds",
    title_builder: ->(outcome:) {
      "#{outcome['description']} has #{outcome['name'].downcase} #{outcome['point']} receiving TDs"
    }
  },
  player_reception_yds: {
    source: :odds_api,
    key: "player_reception_yds",
    title_builder: ->(outcome:) {
      "#{outcome['description']} has #{outcome['name'].downcase} #{outcome['point']} receiving yards"
    }
  },
  player_rush_attempts: {
    source: :odds_api,
    key: "player_rush_attempts",
    title_builder: ->(outcome:) {
      "#{outcome['description']} has #{outcome['name'].downcase} #{outcome['point']} rush attempts"
    }
  },
	player_rush_longest: { label: "Player Longest Rush", source: :odds_api, key: "player_rush_longest" }, # did not include in sample data
  player_rush_tds: {
    source: :odds_api,
    key: "player_rush_tds",
    title_builder: ->(outcome:) {
      "#{outcome['description']} has #{outcome['name'].downcase} #{outcome['point']} rushing TDs"
    }
  },
  player_rush_yds: {
    source: :odds_api,
    key: "player_rush_yds",
    title_builder: ->(outcome:) {
      "#{outcome['description']} has #{outcome['name'].downcase} #{outcome['point']} rushing yards"
    }
  },
  player_sacks: {
    source: :odds_api,
    key: "player_sacks",
    title_builder: ->(outcome:) {
      "#{outcome['description']} has #{outcome['name'].downcase} #{outcome['point']} sacks"
    }
  },
  player_anytime_td: { label: "Anytime TD Scorer", source: :odds_api, key: "player_anytime_td" }, # did not include in sample data
  player_1st_td: { label: "First TD Scorer", source: :odds_api, key: "player_1st_td" }, # did not include in sample data
  player_last_td: { label: "Last TD Scorer", source: :odds_api, key: "player_last_td" } # did not include in sample data
}
