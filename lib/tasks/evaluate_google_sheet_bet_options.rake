namespace :google_sheet do
  desc "Evaluate and update bet options from Google Sheets"
  task evaluate: :environment do
    sheet_id = 'your_google_sheet_id'
    fetcher = GoogleSheetFetcher.new(sheet_id)

    puts "Fetching games data for evaluation."
    games_data = fetcher.fetch_data('Games')
    puts "Fetching bet options data for evaluation."
    bet_options_data = fetcher.fetch_data('Bet Options')

    GoogleSheetImporter.update_bet_options_and_bets(games_data, bet_options_data)
    puts "Bet options evaluated and updated successfully."
  end
end
