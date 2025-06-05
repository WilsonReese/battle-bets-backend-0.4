# lib/tasks/battles.rake
namespace :battles do
  desc "Set all in_progress battles to completed and update leaderboard"
  task complete_in_progress: :environment do
    battles = Battle.in_progress
    count = battles.count

    if count.zero?
      puts "⚠️ No battles with status 'in_progress' found."
      next
    end

    battles.find_each do |battle|
      battle.complete!
    end

    puts "✅ Completed and scored #{count} battles."
  end

  desc "Roll current battles to a specified week. Usage: rake battles:roll_to_week[5]"
  task :roll_to_week, [:week] => :environment do |t, args|
    week = args[:week].to_i

    if week <= 0
      puts "❌ Please provide a valid week number, e.g., rake battles:roll_to_week[5]"
      next
    end

    puts "➡️ Rolling battles to week #{week}..."

    # Step 1: Unset all current battles
    Battle.where(current: true).update_all(current: false)
    puts "✅ Cleared current status from previous battles"

    # Step 2: Find eligible league seasons
    eligible_league_season_ids = LeagueSeason.where("start_week <= ?", week).pluck(:id)

    # Step 3: Update battles for the given week in eligible league seasons
    updated_count = Battle
      .where(week: week, league_season_id: eligible_league_season_ids)
      .update_all(current: true, status: Battle.statuses[:in_progress])

    puts "✅ Marked #{updated_count} battles as current and in_progress for week #{week}"
  end
end
