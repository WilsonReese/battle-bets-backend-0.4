namespace :csv do
    desc "Import data from CSV files"
    task import: :environment do
    	puts "Importing games file."
      games_file = Rails.root.join('lib', 'data', 'Battle Bets - Master - Games.csv')
      CsvImporter.import_games(games_file)
			puts "Successfully imported games file."

			puts "Importing bet options file."
      bet_options_file = Rails.root.join('lib', 'data', 'Battle Bets - Master - Bet Options.csv')
      CsvImporter.import_bet_options(bet_options_file)
			puts "Successfully imported games file."
  
  
      # Delete the files after import
			puts "Deleting CSVs/"
      File.delete(games_file) if File.exist?(games_file)
      File.delete(bet_options_file) if File.exist?(bet_options_file)
      puts "CSV files deleted successfully."
    end
  end