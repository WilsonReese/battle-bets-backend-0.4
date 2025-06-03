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
end
