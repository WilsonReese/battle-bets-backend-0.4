namespace :google_sheet do
  desc "Evaluate and update bet options from Google Sheets"
  task evaluate: :environment do
    sheet_id = '1OwUe9d9VEP032f8TOnOvqrbVUsDq4O6kS4PWQ4phtZ8'
    fetcher = GoogleSheetFetcher.new(sheet_id)

    puts "Fetching games data for evaluation."
    games_data = fetcher.fetch_data('Games', 'A:D')
    puts "Fetching bet options data for evaluation."
    bet_options_data = fetcher.fetch_data('Bet Options', 'A:E')

    GoogleSheetImporter.update_bet_options_and_bets(games_data, bet_options_data)
    puts "Bet options evaluated and updated successfully."
  end
end