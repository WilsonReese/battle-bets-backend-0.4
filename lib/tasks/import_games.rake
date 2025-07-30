require 'net/http'
require 'uri'
require 'json'

namespace :games do
  # ------------- TASK 1A ------------- #
  # Import all games for a given week
  desc "Import games from ESPN for a given week and season year"
  task :import_week, [:week, :season_year] => :environment do |t, args|

    puts "🧹 Clearing existing games..."
    # Game.delete_all # Hard code / temporary - This needs to be fixed to just delete games from the season and year

    week = args[:week].to_i
    season_year = args[:season_year].to_i

    if week <= 0 || season_year <= 0
      puts "❌ Please provide a valid week and season year"
      next
    end

    season = Season.find_by(year: season_year)

    if season.nil?
      puts "❌ No season found for year #{season_year}"
      next
    end

    EspnGameImporter.new(week: week, season: season).call
    puts "🎉 Done importing games for week #{week} of season #{season_year}"
  end

  # ------------- TASK 1B ------------- #
  # Import games for a Team's schedule
  desc "Import ESPN games for a given team and season"
  task import_team_schedule: :environment do
    require "net/http"
    require "json"

    espn_team_id = 238  # Vanderbilt
    season = 2023

    url = URI("https://site.api.espn.com/apis/site/v2/sports/football/college-football/teams/#{espn_team_id}/schedule?season=#{season}")
    response = Net::HTTP.get(url)
    data = JSON.parse(response)

    events = data["events"]
    puts "📅 Found #{events.length} events for team #{espn_team_id}..."

    events.each do |event|
      game_id = event["id"]
      start_time = event["date"]
      week = event["week"]["number"]
      competitors = event["competitions"][0]["competitors"]
      season = Season.find_by(year: 2023)
      if season.nil?
        puts "❌ No season found for year 2023"
        return
      end

      home_team_id = nil
      away_team_id = nil

      competitors.each do |comp|
        team_id = comp["team"]["id"].to_i
        team = Team.find_by(espn_id: team_id)

        unless team
          puts "⚠️ Could not find team with ESPN ID #{team_id}"
          next
        end

        if comp["homeAway"] == "home"
          home_team_id = team.id
        elsif comp["homeAway"] == "away"
          away_team_id = team.id
        end
      end

      if home_team_id && away_team_id
        game = Game.find_or_initialize_by(espn_id: game_id)
        game.update!(
          week: week,
          start_time: start_time,
          home_team_id: home_team_id,
          away_team_id: away_team_id,
          season_id: season.id,
          espn_id: game_id
        )
        puts "✅ Saved game #{event["shortName"]} (Week #{week})"
      else
        puts "❌ Skipped game #{game_id} — missing team mapping"
      end
    end

    puts "🏁 Finished importing team schedule for #{season}"
  end

  # ------------- TASK 2A ------------- #
  desc "Temporarily seed every missing api_sports_io_game_id with a unique placeholder"
  task add_temporary_api_sports_io_game_id: :environment do
    Game.where(api_sports_io_game_id: nil).find_each do |g|
      placeholder = "temp_9401_#{g.id}"
      g.update_column(:api_sports_io_game_id, placeholder)
    end
    puts "✅ Assigned unique temp IDs to #{Game.where("api_sports_io_game_id LIKE 'temp_9401_%'").count} games"
  end

  # ------------- TASK 2B ------------- #
  # Task for getting the api-sports-io ids for each game
  # This currently takes from the api sports io game data, which is 12 games from 2023
  desc "Backfill api_sports_io_game_id from local JSON, with debug and type-casting"
  task backfill_api_sports_game_ids: :environment do
    path = Rails.root.join("lib", "data", "api_sports_io_game_data.json")
    unless File.exist?(path)
      puts "❌ File not found at #{path}"
      exit(1)
    end

    puts "📂 Loading API Sports IO games..."
    json_data = JSON.parse(File.read(path))["response"]

    puts "ℹ️  JSON entries: #{json_data.size}"
    puts "ℹ️  Sample entry date: #{json_data.first.dig("game","date","date")}"

    skipped_for_missing_team_id = 0
    updated   = 0
    unmatched = []

    Game.where(api_sports_io_game_id: nil).find_each do |game|
      ht_id = game.home_team&.api_sports_io_id
      at_id = game.away_team&.api_sports_io_id

      if ht_id.blank? || at_id.blank?
        skipped_for_missing_team_id += 1
        puts "⚠️  SKIP Game##{game.id}: missing team API IDs (home: #{ht_id.inspect}, away: #{at_id.inspect})"
        next
      end

      # Cast both sides to integer for a clean compare
      ht_id_i = ht_id.to_i
      at_id_i = at_id.to_i

      # Find all candidate entries with matching team IDs
      candidates = json_data.select do |entry|
        entry_home = entry["teams"]["home"]["id"].to_i
        entry_away = entry["teams"]["away"]["id"].to_i
        entry_home == ht_id_i && entry_away == at_id_i
      end

      # If more than one candidate, narrow by timestamp within ±1 day
      if candidates.size > 1
        window_start = game.start_time.to_i - 86_400
        window_end   = game.start_time.to_i + 86_400

        candidates.select! do |e|
          ts = e.dig("game", "date", "timestamp")
          ts && ts.between?(window_start, window_end)
        end
      end

      case candidates.size
      when 1
        entry = candidates.first
        game.update!(api_sports_io_game_id: entry.dig("game", "id"))
        puts "✅ Matched Game##{game.id} (#{game.start_time.to_date}) → API ID #{entry['game']['id']}"
        updated += 1

      when 0
        unmatched << game
        puts "❌ NO MATCH for Game##{game.id}: teams(#{ht_id_i}/#{at_id_i}) date=#{game.start_time.to_date}"

      else
        unmatched << game
        puts "❌ AMBIGUOUS for Game##{game.id}: #{candidates.size} candidates"
      end
    end

    puts "\n🏁 Finished."
    puts "🚫 Skipped (missing team IDs): #{skipped_for_missing_team_id}"
    puts "✅ Updated: #{updated}"
    puts "❌ Unmatched or ambiguous: #{unmatched.size}"
    if unmatched.any?
      puts "\n📋 Unmatched Game IDs:"
      unmatched.each do |g|
        puts " • ##{g.id}: #{g.home_team.name} @ #{g.away_team.name} on #{g.start_time.to_date}"
      end
    end
  end

  # ------------- TASK 2C ------------- #
  # Task for getting the api-sports-io ids for each game but actually using the JSON response
  desc "Backfill api_sports_io_game_id by fetching from API‑Sports instead of local JSON"
  task :add_api_sports_game_ids, [:league_id, :season_year] => :environment do |t, args|
    # allow arguments or default to league=2 (NCAA) season=2025
    args.with_defaults(league_id: 2, season_year: 2025)

    puts "🌐 Fetching games from API‑Sports (league=#{args.league_id}, season=#{args.season_year})…"
    uri = URI("#{API_SPORTS_IO_BASE_URL}/games")
    uri.query = URI.encode_www_form(
      league: args.league_id,
      season: args.season_year
    )

    req = Net::HTTP::Get.new(uri)
    req['x-apisports-key'] = API_SPORTS_IO_KEY
    req['Accept'] = 'application/json'

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    unless res.is_a?(Net::HTTPSuccess)
      puts "❌ HTTP Error #{res.code}: #{res.message}"
      exit(1)
    end

    payload    = JSON.parse(res.body)
    game_data  = payload['response'] || []
    puts "✅ Retrieved #{game_data.size} games from API‑Sports"

    skipped_for_missing_team = 0
    updated   = 0
    unmatched = []

    Game.where(api_sports_io_game_id: nil).find_each do |game|
      ht_id = game.home_team&.api_sports_io_id
      at_id = game.away_team&.api_sports_io_id

      if ht_id.blank? || at_id.blank?
        skipped_for_missing_team += 1
        puts "⚠️  SKIP ##{game.id}: missing team API IDs (home: #{ht_id.inspect}, away: #{at_id.inspect})"
        next
      end

      ht_i = ht_id.to_i
      at_i = at_id.to_i

      # find candidates matching both team IDs
      candidates = game_data.select do |e|
        home_id = e.dig('teams','home','id').to_i
        away_id = e.dig('teams','away','id').to_i

        # either exact or reversed
        (home_id == ht_i && away_id == at_i) ||
        (home_id == at_i && away_id == ht_i)
      end

      # if multiple, narrow by timestamp ±1 day
      if candidates.size > 1
        window = (game.start_time.to_i - 86_400)..(game.start_time.to_i + 86_400)
        candidates.select! do |e|
          ts = e.dig('game','date','timestamp')
          ts && window.cover?(ts)
        end
      end

      case candidates.size
      when 1
        entry = candidates.first
        game.update!(api_sports_io_game_id: entry.dig('game','id'))
        puts "✅ Matched ##{game.id} on #{game.start_time.to_date} → API ID #{entry['game']['id']}"
        updated += 1

      when 0
        unmatched << game
        puts "❌ NO MATCH for ##{game.id} (#{ht_i}/#{at_i} on #{game.start_time.to_date})"

      else
        unmatched << game
        puts "❌ AMBIGUOUS for ##{game.id}: #{candidates.size} candidates"
      end
    end

    puts "\n🏁 Done!"
    puts "• Skipped (missing team IDs): #{skipped_for_missing_team}"
    puts "• Updated: #{updated}"
    puts "• Unmatched or ambiguous: #{unmatched.size}"
    if unmatched.any?
      puts "\n— Unmatched Games —"
      unmatched.each do |g|
        puts "  • ##{g.id}: #{g.home_team&.name} @ #{g.away_team&.name} (#{g.start_time.to_date})"
      end
    end
  end

  # ------------- TASK 3A ------------- #
  desc "Populate games.odds_api_game_id by matching against lib/data/odds_api_game_data.json"
  task update_odds_api_game_ids: :environment do
    file_path = Rails.root.join("lib", "data", "odds_api_game_data.json")
    payload   = JSON.parse(File.read(file_path))

    # Group by [home_team, away_team] for fast lookup
    by_matchup = payload.group_by { |e| [e["home_team"], e["away_team"]] }

    updated   = []
    unmatched = []

    Game.where(odds_api_game_id: nil).find_each do |game|
      ht = game.home_team.long_name_odds_api
      at = game.away_team.long_name_odds_api

      candidates = by_matchup[[ht, at]] || []

      # If more than one, filter by start_time ± 1 day
      if candidates.size > 1
        window = (game.start_time - 1.day)..(game.start_time + 1.day)
        candidates.select! do |entry|
          commence = Time.iso8601(entry["commence_time"])
          window.cover?(commence)
        end
      end

      if candidates.one?
        entry = candidates.first
        game.update!(odds_api_game_id: entry["id"])
        updated << [game.id, entry["id"]]
        puts "✔ Game##{game.id} → #{entry['id']}"

      else
        unmatched << game
        puts "– Could not match Game##{game.id} (#{candidates.size} candidates)"
      end
    end

    # Summary
    puts "\n✅ Done."
    puts "🔄 Updated: #{updated.size}"
    puts "❌ Unmatched: #{unmatched.size}"
    if unmatched.any?
      puts "\n📋 Unmatched games:"
      unmatched.each do |g|
        puts " • Game##{g.id}: #{g.home_team.name} @ #{g.away_team.name} on #{g.start_time.to_date}"
      end
    end
  end

  # ========== TASK 3B ========== #
  desc "Assign a temporary odds_api_game_id to all games that are missing one"
  task add_temporary_odds_api_game_id: :environment do
    TEMP_ID = "20740de7481ec1f20c2efbc30852f6c6"

    games_to_update = Game.where(odds_api_game_id: nil)
    count = games_to_update.size

    if count.zero?
      puts "ℹ️  No games without an odds_api_game_id—nothing to do."
    else
      games_to_update.update_all(odds_api_game_id: TEMP_ID)
      puts "✅ Updated #{count} game#{'s' if count != 1} with temporary odds_api_game_id=#{TEMP_ID}"
    end
  end

end