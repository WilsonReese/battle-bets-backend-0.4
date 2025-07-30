# pulled from your encrypted credentials
API_SPORTS_IO_KEY  = Rails.application.credentials.dig(:api_sports_io, :key)

# base URL for all API‑Sports IO calls
API_SPORTS_IO_BASE_URL = "https://v1.american-football.api-sports.io"