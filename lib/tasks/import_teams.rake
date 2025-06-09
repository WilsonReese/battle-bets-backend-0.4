namespace :teams do
  desc "Import D1 College Football Teams from ESPN"
  task import_from_espn: :environment do
    require "net/http"
    require "json"

    puts "🧹 Clearing existing teams..."
    Game.delete_all
    Team.delete_all

    url = URI("https://site.api.espn.com/apis/site/v2/sports/football/college-football/teams?limit=700&groupType=conference&enable=groups")
    response = Net::HTTP.get(url)
    data = JSON.parse(response)

    count = 0

    data["sports"][0]["leagues"][0]["groups"].each do |conference|
      conference_name = conference["midsizeName"]

      teams = conference["teams"]
      next if teams.nil? || teams.empty?

      teams.each do |team|
        espn_id = team["id"].to_i
        name = team["nickname"]

        if name.blank? || espn_id.blank? || conference_name.blank?
          puts "⚠️ Skipping invalid team: #{team.inspect}"
          next
        end

        Team.create!(
          espn_id: espn_id,
          name: name,
          conference: conference_name
        )

        count += 1
        puts "✅ Saved team: #{name} (#{conference_name}) with ESPN ID #{espn_id}"
      end
    end

    puts "🏁 Done importing teams from ESPN."
    puts "📊 Imported #{count} teams."
  end
end
