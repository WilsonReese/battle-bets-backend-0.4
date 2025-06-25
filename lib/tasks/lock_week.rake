namespace :betslip do
  # Usage:
  #   rake "betslip:lock_week[SEASON_YEAR,WEEK]"
  # Example:
  #   rake "betslip:lock_week[2025,5]"
  #
  desc "Lock all battles, betslips and games for a given season & week"
  task :lock_week, [:season_year, :week] => :environment do |_t, args|
    unless args.season_year && args.week
      puts "❌  Usage: rake \"betslip:lock_week[YYYY,W]\""
      exit 1
    end

    season_year = args.season_year.to_i
    week        = args.week.to_i

    season = Season.find_by(year: season_year)
    unless season
      puts "❌  No Season found for year #{season_year}"
      exit 1
    end

    # ───────────────────────────────────────────────────────────
    # 1. Battles for the requested season/week
    #    (via league_season → season)
    # ───────────────────────────────────────────────────────────
    # battle_count = Battle
    #   .joins(league_season: :season)
    #   .where(seasons: { id: season.id }, week: week)
    #   .count

    # puts "ℹ️  Found #{battle_count} Battle(s) for Season #{season_year}, Week #{week}"

    battles = Battle
                .joins(league_season: :season)
                .where(seasons: { id: season.id }, week: week)

    puts "ℹ️  Found #{battles.size} Battle(s) for Season #{season_year}, Week #{week}"

    # ────────────────── lock them ──────────────────────────────
    battles.update_all(locked: true)
    puts "🔒  Locked all Battles"

    # ────────────────── lock associated betslips ──────────────
    betslip_count = Betslip.where(battle_id: battles.ids)
                           .update_all(locked: true)
    puts "🔒  Locked #{betslip_count} Betslip(s)"

    # ────────────────── flag the games ─────────────────────────
    games = Game.where(season: season, week: week)
    games.update_all(battles_locked: true)
    puts "✅  Flagged #{games.size} Game(s) as battles_locked"
  end
end