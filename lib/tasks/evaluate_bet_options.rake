namespace :bet_options do
    desc "Import and update bet options from a CSV file"
    task evaluate: :environment do
      puts "Evaluating bet options and updating bets"
      games_file = Rails.root.join('lib', 'data', 'Battle Bets - Master - Games.csv')
      bet_options_file = Rails.root.join('lib', 'data', 'Battle Bets - Master - Bet Options.csv')
      CsvImporter.update_bet_options_and_bets(games_file, bet_options_file)
      puts "Complete"
    end
  end