module BetOptions
  module Generators
    module Helpers
      PropBetsRegistry = {
        overtime: {
          source: :api_sports_io,
          id: 12,
          title_builder: ->(value:, home_team:, away_team:) {
            return nil if value["value"].downcase == "no"
            "Game goes to OT"
          }
        },
        first_team_to_score: {
          source: :api_sports_io,
          id: 52,
          title_builder: ->(value:, home_team:, away_team:) {
            team = value["value"].downcase == "home" ? home_team.name : away_team.name
            "#{team} scores first"
          }
        },
        multi_td_scorer: {
          label: "Multi Touchdown Scorer",
          source: :api_sports_io,
          id: 50
        }, # did not include in sample data
        btts: {
          label: "Both Teams to Score",
          source: :odds_api,
          key: "btts"
        }, # did not include in sample data
        player_pass_tds: {
          source: :odds_api,
          key: "player_pass_tds",
          title_builder: ->(outcome:) {
            "#{outcome['description']} throws #{outcome['name'].downcase} #{outcome['point']} passing TDs"
          }
        },
        player_pass_yds: {
          source: :odds_api,
          key: "player_pass_yds",
          title_builder: ->(outcome:) {
            "#{outcome['description']} throws for #{outcome['name'].downcase} #{outcome['point']} yards"
          }
        },
        player_receptions: {
          source: :odds_api,
          key: "player_receptions",
          title_builder: ->(outcome:) {
            "#{outcome['description']} has #{outcome['name'].downcase} #{outcome['point']} receptions"
          }
        },
        player_reception_tds: {
          source: :odds_api,
          key: "player_reception_tds",
          title_builder: ->(outcome:) {
            "#{outcome['description']} has #{outcome['name'].downcase} #{outcome['point']} receiving TDs"
          }
        },
        player_reception_yds: {
          source: :odds_api,
          key: "player_reception_yds",
          title_builder: ->(outcome:) {
            "#{outcome['description']} has #{outcome['name'].downcase} #{outcome['point']} receiving yards"
          }
        },
        player_rush_attempts: {
          source: :odds_api,
          key: "player_rush_attempts",
          title_builder: ->(outcome:) {
            "#{outcome['description']} has #{outcome['name'].downcase} #{outcome['point']} rush attempts"
          }
        },
        player_rush_longest: { label: "Player Longest Rush", source: :odds_api, key: "player_rush_longest" }, # did not include in sample data
        player_rush_tds: {
          source: :odds_api,
          key: "player_rush_tds",
          title_builder: ->(outcome:) {
            "#{outcome['description']} has #{outcome['name'].downcase} #{outcome['point']} rushing TDs"
          }
        },
        player_rush_yds: {
          source: :odds_api,
          key: "player_rush_yds",
          title_builder: ->(outcome:) {
            "#{outcome['description']} has #{outcome['name'].downcase} #{outcome['point']} rushing yards"
          }
        },
        player_sacks: {
          source: :odds_api,
          key: "player_sacks",
          title_builder: ->(outcome:) {
            "#{outcome['description']} has #{outcome['name'].downcase} #{outcome['point']} sacks"
          }
        },
        player_anytime_td: { label: "Anytime TD Scorer", source: :odds_api, key: "player_anytime_td" }, # did not include in sample data
        player_1st_td: { label: "First TD Scorer", source: :odds_api, key: "player_1st_td" }, # did not include in sample data
        player_last_td: { label: "Last TD Scorer", source: :odds_api, key: "player_last_td" } # did not include in sample data
      }.freeze
    end
  end
end