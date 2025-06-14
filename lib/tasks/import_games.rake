namespace :games do
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
end