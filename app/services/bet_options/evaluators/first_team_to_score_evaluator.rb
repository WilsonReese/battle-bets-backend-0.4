module BetOptions
  module Evaluators
    class FirstTeamToScoreEvaluator
      def initialize(game, events)
        @game   = game
        @events = events
      end

      def call
        opts = @game.bet_options.where(bet_flavor: :first_team_to_score)
        return puts "ℹ️  No first_team_to_score BetOptions for Game##{@game.id}" if opts.empty?

        # 1️⃣ Take the very first scoring event
        first_event = @events.first
        unless first_event && first_event["team"] && first_event["team"]["id"]
          puts "⚠️  No valid first event in game_events"
          return
        end

        scoring_team_id = first_event.dig("team", "id").to_i
        scoring_team    = Team.find_by(api_sports_io_id: scoring_team_id)

        unless scoring_team
          puts "⚠️  No Team with api_sports_io_id=#{scoring_team_id}"
          return
        end

        puts "\n🥇 Evaluating first team to score: #{scoring_team.name}"

        # 2️⃣ For each bet_option, check if its title includes the team name
        opts.each do |opt|
          # 1) Strip the trailing " scores first" to isolate the name
          team_in_title = opt.title.sub(/\s+scores first\z/, "")

          # 2) Exact match against the scoring_team.name
          won = (team_in_title == scoring_team.name)

          opt.update!(success: won)
          result = won ? "✅ win" : "❌ loss"
          puts "  • ##{opt.id} (#{opt.title}): #{result}"
        end
      end
    end
  end
end