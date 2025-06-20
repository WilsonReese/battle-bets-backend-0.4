namespace :bet_options do
  desc "Generate ALL bet options for a given season and week. Usage: rake bet_options:generate[2025,1]"
  task :generate, [:season_year, :week] => :environment do |t, args|
    year = args[:season_year].to_i
    wk   = args[:week].to_i
    if year <= 0 || wk <= 0
      puts "❌ Usage: rake bet_options:generate[<season_year>,<week>]"
      exit 1
    end

    BetOptions::Generators::Generator.new(year, wk).run
  end
end