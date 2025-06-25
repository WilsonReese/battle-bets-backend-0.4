# lib/tasks/lock_betslips.rake
namespace :betslip do
  desc "Lock all betslips for battles ongoing on a specified date"
  task lock_betslips: :environment do
    date_str = ENV['date']
    if date_str.nil?
      puts "Please provide a date in the format YYYY-MM-DD. Example: rake betslip:lock_betslips date=2024-10-13"
      exit
    end

    # Parse the date
    begin
      date = Date.parse(date_str)
    rescue ArgumentError
      puts "Invalid date format. Please provide a valid date in the format YYYY-MM-DD."
      exit
    end

    # Define the start and end range for the entire day
    date_start = date.beginning_of_day
    date_end = date.end_of_day

    # Find battles that are ongoing on the specified date
    battles = Battle.where("start_date <= ? AND end_date >= ?", date_end, date_start)
    if battles.empty?
      puts "No battles found for date: #{date}"
      exit
    end

    # Lock the battles
    locked_battles_count = 0
    battles.find_each do |battle|
      unless battle.locked
        battle.update!(locked: true)
        locked_battles_count += 1
        puts "Locked Battle ID #{battle.id}"
      end
    end

    # Lock betslips associated with the found battles
    betslips_to_lock = Betslip.where(battle_id: battles.pluck(:id))
    locked_betslips_count = 0

    betslips_to_lock.find_each do |betslip|
      betslip.update_column(:locked, true) # Directly updates the column, bypassing callbacks and validations
      locked_betslips_count += 1
      puts "Locked Betslip ID #{betslip.id} for Battle ID #{betslip.battle_id}"
    end

    puts "Locked #{locked_battles_count} battle(s) and #{locked_betslips_count} betslip(s) for battles ongoing on #{date}."
  end
end