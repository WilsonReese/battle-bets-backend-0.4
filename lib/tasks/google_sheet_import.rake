# namespace :google_sheet do
#   desc "Import data from Google Sheets"
#   task import: :environment do
#     sheet_id = '1OwUe9d9VEP032f8TOnOvqrbVUsDq4O6kS4PWQ4phtZ8' # Comes from the URL of the sheet
#     fetcher = GoogleSheetFetcher.new(sheet_id)

#     puts "Skip fetching and importing games data."
#     # games_data = fetcher.fetch_data('Games', 'A:D') # Replace 'Games' with your tab name
#     # GoogleSheetImporter.import_games(games_data)
#     puts "Skipped importing games data successfully."

#     puts "Fetching and importing bet options data."
#     bet_options_data = fetcher.fetch_data('Bet Options', 'A:E') # Replace with your tab name
#     GoogleSheetImporter.import_bet_options(bet_options_data)
#     puts "Bet options data imported successfully."
#   end
# end