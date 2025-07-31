# Your secret key from credentials
ODDS_API_KEY = Rails.application.credentials.dig(:odds_api, :key)

# Base URL for all calls
ODDS_API_BASE_URL = "https://api.the-odds-api.com"