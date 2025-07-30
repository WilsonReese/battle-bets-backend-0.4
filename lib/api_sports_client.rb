# lib/api_sports_client.rb
require 'net/http'
require 'uri'
require 'json'

class ApiSportsClient
  BASE = API_SPORTS_IO_BASE_URL

  # Generic fetch, raising on HTTP errors
  def self.fetch(path, query = {})
    uri = URI.join(BASE, path)
    uri.query = URI.encode_www_form(query)

    req = Net::HTTP::Get.new(uri)
    req['x-apisports-key'] = API_SPORTS_IO_KEY
    req['Accept']          = 'application/json'

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(req)
    end

    unless res.is_a?(Net::HTTPSuccess)
      raise "API‑Sports IO error #{res.code}: #{res.message}"
    end

    JSON.parse(res.body)
  end

  def self.games(params = {})
    fetch('/games', params)
  end

  # add more helpers as needed...
end