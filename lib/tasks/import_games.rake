namespace :games do
  # Import all games for a given week

  desc "Import games from ESPN for a given week and season year"
  task :import_week, [:week, :season_year] => :environment do |t, args|

    puts "🧹 Clearing existing games..."
    Game.delete_all # Hard code / temporary - This needs to be fixed to just delete games from the season and year

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

  # Task for getting the api-sports-io ids for each team
  desc "Backfill API Sports IO Game IDs using local JSON data with fuzzy date matching"
  task backfill_api_sports_game_ids: :environment do
    require "json"
    require "date"

    path = Rails.root.join("lib", "data", "api_sports_io_game_data.json")
    unless File.exist?(path)
      puts "❌ File not found at #{path}"
      next
    end

    puts "📂 Loading API Sports IO games..."
    json_data = JSON.parse(File.read(path))["response"]

    unmatched = []

    Game.where(api_sports_io_game_id: nil).find_each do |game|
      game_date = game.start_time.to_date
      home_team_id = game.home_team&.api_sports_io_id
      away_team_id = game.away_team&.api_sports_io_id

      if home_team_id.nil? || away_team_id.nil?
        puts "⚠️ Skipping game #{game.id} due to missing team API IDs"
        next
      end

      match = json_data.find do |entry|
        begin
          entry_date = Date.parse(entry["game"]["date"]["date"])
        rescue
          next
        end

        date_close_enough = (entry_date - game_date).abs <= 1
        teams_match = home_team_id == entry["teams"]["home"]["id"] &&
                      away_team_id == entry["teams"]["away"]["id"]

        date_close_enough && teams_match
      end

      if match
        game.update!(api_sports_io_game_id: match["game"]["id"])
        puts "✅ Matched Game #{game.espn_id} → API Game #{match['game']['id']}"
      else
        unmatched << game.espn_id
        puts "❌ No match for Game #{game.espn_id} (#{game_date}, Home: #{home_team_id}, Away: #{away_team_id})"
      end
    end

    puts "🏁 Finished backfilling API game IDs."
    puts "⚠️ #{unmatched.count} unmatched games." if unmatched.any?
  end

end