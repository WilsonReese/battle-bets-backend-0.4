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

  # desc "Roll current battles to a specified week. Usage: rake battles:roll_to_week[5]"
  # task :roll_to_week, [:week] => :environment do |_, args|
  #   week = args[:week].to_i

  #   if week <= 0
  #     puts "❌ Please provide a valid week number, e.g., rake battles:roll_to_week[5]"
  #     next
  #   end

  #   puts "➡️ Rolling battles to week #{week}..."

  #   # Step 1: Unset all current battles
  #   Battle.where(current: true).update_all(current: false)
  #   puts "✅ Cleared current status from previous battles"

  #   # Step 2: Get eligible league_season_ids
  #   eligible_ids = LeagueSeason.where("start_week <= ?", week).pluck(:id)

  #   if eligible_ids.empty?
  #     puts "⚠️ No eligible league seasons found for week #{week}"
  #     next
  #   end

  #   # Step 3: Find existing battles for this week
  #   existing_battles = Battle.where(week: week, league_season_id: eligible_ids).index_by(&:league_season_id)

  #   # Step 4: Create missing battles in bulk
  #   new_battles = []
  #   base_date = Date.new(2025, 8, 24) + (week - 1).weeks
  #   start_time = base_date.beginning_of_day
  #   end_time = (base_date + 6.days).end_of_day

  #   (eligible_ids - existing_battles.keys).each do |league_season_id|
  #     new_battles << {
  #       league_season_id: league_season_id,
  #       week: week,
  #       start_date: start_time,
  #       end_date: end_time,
  #       status: Battle.statuses[:in_progress],
  #       current: true,
  #       locked: false,
  #       created_at: Time.current,
  #       updated_at: Time.current
  #     }
  #   end

  #   Battle.insert_all!(new_battles) if new_battles.any?
  #   puts "✅ Created #{new_battles.size} new battles for week #{week}"

  #   # Step 5: Update existing battles in bulk
  #   updated_count = Battle
  #     .where(week: week, league_season_id: existing_battles.keys)
  #     .update_all(status: Battle.statuses[:in_progress], current: true)
  #   puts "✅ Updated #{updated_count} existing battles for week #{week}"

  #   # Step 6: Update current_week for all seasons
  #   Season.update_all(current_week: week)
  #   puts "✅ Updated current_week for all seasons to #{week}"
  # end
  # 
  
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
