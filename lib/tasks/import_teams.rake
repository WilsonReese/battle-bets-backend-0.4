namespace :teams do
  desc "Import D1 College Football Teams from ESPN"
  task import_from_espn: :environment do
    require "net/http"
    require "json"

    puts "🧹 Clearing existing teams..."
    Game.delete_all
    Team.delete_all

    # Load API Sports IO team data from JSON
    api_sports_data_path = Rails.root.join("lib", "data", "api_sports_io_team_data.json")
    api_sports_data = JSON.parse(File.read(api_sports_data_path))["response"]

    # Normalize name map
    api_sports_name_map = api_sports_data.each_with_object({}) do |team, hash|
      next unless team["name"].present?

      normalized_name = team["name"].strip.downcase
      hash[normalized_name] = team["id"]
    end

    # Load manual discrepancies
    manual_path = Rails.root.join('lib', 'data', 'api_sports_io_discrepancies.json')
    manual_name_map = JSON.parse(File.read(manual_path))
    manual_name_map.transform_keys! { |k| k.strip.downcase }

    url = URI("https://site.api.espn.com/apis/site/v2/sports/football/college-football/teams?limit=700&groupType=conference&enable=groups")
    response = Net::HTTP.get(url)
    data = JSON.parse(response)

    count = 0
    unmatched = []

    data["sports"][0]["leagues"][0]["groups"].each do |conference|
      conference_name = conference["midsizeName"]

      teams = conference["teams"]
      next if teams.nil? || teams.empty?

      teams.each do |team|
        espn_id = team["id"].to_i
        name = team["nickname"]
        location = team["location"]
        long_name=team["displayName"]

        if name.blank? || espn_id.blank? || conference_name.blank?
          puts "⚠️ Skipping invalid team: #{team.inspect}"
          next
        end

        normalized_name = name.strip.downcase
        normalized_location = location&.strip&.downcase

        # Step 1: Try matching by nickname
        api_sports_io_id = api_sports_name_map[normalized_name]

        # Step 2: Try matching by location
        api_sports_io_id ||= api_sports_name_map[normalized_location] if normalized_location.present?

        # Step 3: Try matching using discrepancy map (ESPN name → discrepancy value → API Sports IO name → ID)
        if api_sports_io_id.nil?
          discrepancy_entry = manual_name_map.find do |api_name, espn_value|
            normalized_espn_value = if espn_value.is_a?(Hash)
                                      espn_value["espn_name"].to_s.strip.downcase
                                    else
                                      espn_value.to_s.strip.downcase
                                    end

            normalized_espn_value == normalized_name || normalized_espn_value == normalized_location
          end

          if discrepancy_entry
            api_name, espn_value = discrepancy_entry
            if espn_value.is_a?(Hash) && espn_value["id"]
              api_sports_io_id = espn_value["id"].to_i
            else
              normalized_api_name = api_name.strip.downcase
              api_sports_io_id = api_sports_name_map[normalized_api_name]
            end
          end
        end

        Team.create!(
          espn_id: espn_id,
          name: name,
          conference: conference_name,
          api_sports_io_id: api_sports_io_id, 
          long_name: long_name
        )

        if api_sports_io_id
          puts "✅ Saved team: #{name} (#{location}) → API Sports IO ID #{api_sports_io_id}"
        else
          unmatched << "#{name} (#{location})"
          puts "❌ No match for team: #{name} (#{location})"
        end

        count += 1
        puts "📌 Team saved: #{name} (#{conference_name}) with ESPN ID #{espn_id}"
      end
    end

    puts "🏁 Done importing teams from ESPN."
    puts "📊 Imported #{count} teams."

    if unmatched.any?
      puts "⚠️ Unmatched teams (#{unmatched.count}):"
      unmatched.uniq.each { |name| puts "- #{name}" }
    end
  end

  # Get teams from odds api
  desc "Populate teams.long_name_odds_api using explicit mappings; skip Occidental"
  task update_odds_api_names: :environment do
    file_path   = Rails.root.join("lib", "data", "odds_api_team_data.json")
    api_entries = JSON.parse(File.read(file_path))

    # ————— your explicit Odds-API → Team.long_name mapping —————
    mapping = {
      "Albany"                                 => "UAlbany Great Danes",
      "Appalachian State Mountaineers"         => "App State Mountaineers",
      "Arkansas Pine Bluff Golden Lions"       => "Arkansas-Pine Bluff Golden Lions",
      "Citadel Bulldogs"                       => "The Citadel Bulldogs",
      "Dixie State Trailblazers"               => "Utah Tech Trailblazers",
      "Gardner-Webb Runnin Bulldogs"           => "Gardner-Webb Runnin' Bulldogs",
      "Grambling State Tigers"                 => "Grambling Tigers",
      "Hawaii Rainbow Warriors"                => "Hawai'i Rainbow Warriors",
      "Houston Baptist Huskies"                => "Houston Christian Huskies",
      "Kentucky State University Thorobreds"   => "Kentucky State Thorobreds",
      "LIU Sharks"                             => "Long Island University Sharks",
      "Louisiana Ragin Cajuns"                 => "Louisiana Ragin' Cajuns",
      "McNeese State Cowboys"                  => "McNeese Cowboys",
      "Nicholls State Colonels"                => "Nicholls Colonels",
      # "Occidental Tigers"                      => nil,   # skip
      "Presbyterian College Blue Hose"         => "Presbyterian Blue Hose",
      "Sam Houston State Bearkats"             => "Sam Houston Bearkats",
      "San Jose State Spartans"                => "San José State Spartans",
      "Southeastern Louisiana Lions"           => "SE Louisiana Lions",
      "Southern Mississippi Golden Eagles"      => "Southern Miss Golden Eagles",
      "Southern University Jaguars"            => "Southern Jaguars",
      "Texas A&M-Commerce Lions"               => "East Texas A&M Lions",
      "UMass Minutemen"                        => "East Texas A&M Lions",
      "William and Mary Tribe"                 => "William & Mary Tribe",
      "Yale University Bulldogs"               => "Yale Bulldogs",
      "Youngstown St Penguins"                 => "Youngstown State Penguins",
    }

    updated   = []
    unmatched = []

    api_entries.each do |entry|
      full_name = entry["full_name"]

      if mapping.key?(full_name)
        target = mapping[full_name]

        if target
          team = Team.find_by(long_name: target)
          if team
            team.update!(long_name_odds_api: full_name)
            updated << [team.name, full_name]
            puts "✔ #{team.name} ← #{full_name}"
          else
            unmatched << full_name
            puts "⚠ mapping for “#{full_name}” → “#{target}” but no Team.long_name=`#{target}`"
          end
        else
          puts "⏭ skipping “#{full_name}”"
        end

      else
        # fallback to exact match on long_name
        team = Team.find_by(long_name: full_name)
        if team
          team.update!(long_name_odds_api: full_name)
          updated << [team.name, full_name]
          puts "✔ direct: #{team.name} ← #{full_name}"
        else
          unmatched << full_name
          puts "– no match for “#{full_name}”"
        end
      end
    end

    puts "\n✅ Done."
    puts "🔄 Updated entries: #{updated.size}"
    updated.each { |t, fn| puts " • #{t} ← #{fn}" }

    puts "\n❌ Unmatched entries: #{unmatched.size}"
    unmatched.each { |fn| puts " • #{fn}" } if unmatched.any?
  end
end
