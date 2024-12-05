require 'google/apis/sheets_v4'
require 'googleauth'

class GoogleSheetFetcher
  SHEETS = Google::Apis::SheetsV4
  SCOPE = ['https://www.googleapis.com/auth/spreadsheets.readonly']

  def initialize(sheet_id)
    @sheet_id = sheet_id
    @service = SHEETS::SheetsService.new
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open('config/battle-bets-sheets-api-f42d6b61d979.json'),
      scope: SCOPE
    )
  end

  def fetch_data(tab_name, range = 'A:Z')
    response = @service.get_spreadsheet_values(@sheet_id, "#{tab_name}!#{range}")
    response.values
  end
end