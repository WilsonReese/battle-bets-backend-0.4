namespace :google_sheet do
  desc "Import data from Google Sheets"
  task import: :environment do
    sheet_id = 'your_google_sheet_id'
    fetcher = GoogleSheetFetcher.new(sheet_id)

    puts "Fetching and importing games data."
    games_data = fetcher.fetch_data('Games') # Replace 'Games' with your tab name
    GoogleSheetImporter.import_games(games_data)
    puts "Games data imported successfully."

    puts "Fetching and importing bet options data."
    bet_options_data = fetcher.fetch_data('Bet Options') # Replace with your tab name
    GoogleSheetImporter.import_bet_options(bet_options_data)
    puts "Bet options data imported successfully."
  end
end
