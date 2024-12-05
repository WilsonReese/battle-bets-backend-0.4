require 'google/apis/sheets_v4'
require 'googleauth'

class GoogleSheetFetcher
  SHEETS = Google::Apis::SheetsV4
  SCOPE = ['https://www.googleapis.com/auth/spreadsheets.readonly']

  def initialize(sheet_id)
    @sheet_id = sheet_id
    @service = SHEETS::SheetsService.new

    if Rails.env.production? || Rails.env.staging?
      # Use environment variable for Heroku
      credentials_json = Base64.decode64(ENV['GOOGLE_SHEETS_CREDENTIALS_BASE64'])
      credentials_io = StringIO.new(credentials_json)
    else
      credentials_path = Rails.root.join('config', 'battle-bets-sheets-api-f42d6b61d979.json')
      credentials_io = File.open(credentials_path)
    end
    
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: credentials_io,
      scope: SCOPE
    )
  end

  def fetch_data(tab_name, range = 'A:Z')
    response = @service.get_spreadsheet_values(@sheet_id, "#{tab_name}!#{range}")
    response.values
  end
end