require 'csv'

class CsvImporter
  def self.import_games(file_path)
    @game_id_mapping = {} # Hash to store the simplistic ID to actual game_id mapping

    csv_text = File.read(file_path)
    csv = CSV.parse(csv_text, headers: true)

    csv.each_with_index do |row, index|
    	home_team = Team.find_or_create_by!(name: row['home_team'])
      away_team = Team.find_or_create_by!(name: row['away_team'])
      game = Game.create!(
        start_time: row['start_time'],
        home_team: home_team,
        away_team: away_team
      )

      # Assume simplistic ID is based on the order of rows (1, 2, 3, etc.)
      simplistic_id = index + 1
      @game_id_mapping[simplistic_id] = game.id
    end
  end

  def self.import_bet_options(file_path)
    raise "Games must be imported before Bet Options" if @game_id_mapping.nil?

    csv_text = File.read(file_path)
    csv = CSV.parse(csv_text, headers: true)

    csv.each do |row|
      # Find the actual game_id using the simplistic ID from the CSV
      actual_game_id = @game_id_mapping[row['game_id'].to_i]

      BetOption.create!(
        game_id: actual_game_id, 
        title: row['title'], 
        payout: row['payout'], 
        category: row['category']
      )
    end
  end

  def self.update_bet_options_and_bets(games_file_path, bet_options_file_path)
    # Step 1: Load games and create a hash mapping simplistic IDs to game records
    game_id_mapping = {}
    csv_text_games = File.read(games_file_path)
    csv_games = CSV.parse(csv_text_games, headers: true)
  
    csv_games.each_with_index do |row, index|
      home_team = Team.find_by(name: row['home_team'])
      away_team = Team.find_by(name: row['away_team'])
  
      next unless home_team && away_team # Skip if either team is not found
  
      # Find the game using start_time, home_team_id, and away_team_id
      game = Game.find_by(
        start_time: row['start_time'],
        home_team_id: home_team.id,
        away_team_id: away_team.id
      )
  
      next unless game # Skip if the game is not found

      # Use simplistic ID (assumed to be row order starting from 1) to map to the actual game ID
      simplistic_id = index + 1
      game_id_mapping[simplistic_id] = game.id
    end
  
    # Step 2: Process the bet options and update based on the simplistic game ID
    csv_text_bet_options = File.read(bet_options_file_path)
    csv_bet_options = CSV.parse(csv_text_bet_options, headers: true)
  
    csv_bet_options.each do |row|
      simplistic_game_id = row['game_id'].to_i
      actual_game_id = game_id_mapping[simplistic_game_id]
  
      next unless actual_game_id # Skip if game ID is not found
  
      # Find the BetOption by game_id and title
      bet_option = BetOption.find_by(game_id: actual_game_id, title: row['title'])
      next unless bet_option # Skip if the BetOption is not found
  
      # Only update the success status if there is an explicit value in the CSV
      unless row['success'].nil?
        success_status = row['success'].to_i == 1
        bet_option.update!(success: success_status)
  
        # Update the associated Bets based on the success status
        bet_option.bets.each do |bet|
          amount_won = success_status ? bet.to_win_amount : 0.0
          bet.skip_locked_check = true
          bet.betslip.skip_locked_check = true
          bet.update!(amount_won: amount_won)
        end
      end
    end
  end
end