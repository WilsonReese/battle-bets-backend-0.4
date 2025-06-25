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
    eligible_league_seasons = LeagueSeason.includes(:season, :battles, pool: :pool_memberships)
                                          .where("start_week <= ?", week)

    created_count = 0
    updated_count = 0

    eligible_league_seasons.each do |league_season|
      # Step 3: Create battle if it doesn't exist
      battle = league_season.battles.find_or_initialize_by(week: week)

      if battle.new_record?
        base_date = Date.new(2025, 8, 24) + (week - 1).weeks
        battle.assign_attributes(
          start_date: base_date.beginning_of_day,
          end_date: (base_date + 6.days).end_of_day,
          status: :in_progress,
          current: true,
          locked: false
        )
        battle.save!
        created_count += 1
      else
        battle.update!(status: :in_progress, current: true)
        updated_count += 1
      end
    end

    puts "✅ Created #{created_count} battles and updated #{updated_count} existing ones for week #{week}"

    # Step 4: Update current_week for all seasons (for now)
    Season.update_all(current_week: week)
    puts "✅ Updated current_week for all seasons to #{week}"
  end
end
