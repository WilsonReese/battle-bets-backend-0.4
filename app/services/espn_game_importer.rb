require 'net/http'
require 'json'

class EspnGameImporter
  ESPN_API_URL = "https://site.api.espn.com/apis/site/v2/sports/football/college-football/scoreboard"

  def initialize(week:, season:)
    @week = week
    @season = season
    @eligible_team_ids = Team.eligible_for_import.pluck(:espn_id).map(&:to_s)
  end

  def call
    games_data = fetch_games_from_espn
    return unless games_data

    puts "🎯 Eligible team IDs: #{@eligible_team_ids.inspect}"

    games_data.each do |event|
      competition = event["competitions"]&.first
      next unless competition

      competitor_ids = competition["competitors"].map { |c| c["team"]["id"] } # creates array of competitor ids
      puts "🆚 Competitor IDs for event #{event['id']}: #{competitor_ids.inspect}"

      if (competitor_ids & @eligible_team_ids).any?
        puts "✅ Match found — at least one eligible team"
        create_game_if_needed(event, competition)
      else
        puts "⛔️ Skipping — no eligible teams"
      end
    end
  end

  private

  def fetch_games_from_espn
    url = URI("#{ESPN_API_URL}?week=#{@week}&groups=80")
    response = Net::HTTP.get(url)
    parsed = JSON.parse(response)
    puts "📦 ESPN returned #{parsed['events']&.size || 0} games for week #{@week}"
    parsed["events"]
  rescue => e
    Rails.logger.error("❌ Failed to fetch ESPN games: #{e.message}")
    nil
  end

  def create_game_if_needed(event, competition)
    espn_game_id = event["id"]
    return if Game.exists?(espn_id: espn_game_id)

    home_team_data = competition["competitors"].find { |c| c["homeAway"] == "home" }["team"]
    away_team_data = competition["competitors"].find { |c| c["homeAway"] == "away" }["team"]

    home_team = Team.find_by(espn_id: home_team_data["id"])
    away_team = Team.find_by(espn_id: away_team_data["id"])

    Game.create!(
      espn_id: espn_game_id,
      start_time: competition["date"],
      week: @week,
      season: @season,
      home_team: home_team,
      away_team: away_team
    )

    puts "✅ Created game: #{away_team.name} at #{home_team.name}"
  end
end