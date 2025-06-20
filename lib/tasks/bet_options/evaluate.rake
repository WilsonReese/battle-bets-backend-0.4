namespace :bet_options do
  desc "Evaluate all BetOptions for a given GAME_ID. Usage: rake bet_options:evaluate[<game_id>]"
  task :evaluate, [:game_id] => :environment do |t, args|
    game_id = args[:game_id].to_i
    unless game_id.positive?
      puts "❌ Please pass a valid GAME_ID: rake bet_options:evaluate[123]"
      exit 1
    end

    BetOptions::Evaluators::Evaluator.new(game_id).run
  end
end