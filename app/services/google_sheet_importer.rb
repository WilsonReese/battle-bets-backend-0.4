class GoogleSheetImporter
  def self.import_games(data)
    @game_id_mapping = {}

    data.each_with_index do |row, index|
      next if index.zero? # Skip the header row

      home_team = Team.find_or_create_by!(name: row[0]) # Assuming column 0 is home_team
      away_team = Team.find_or_create_by!(name: row[1]) # Assuming column 1 is away_team
      game = Game.create!(
        start_time: row[2], # Assuming column 2 is start_time
        home_team: home_team,
        away_team: away_team
      )

      simplistic_id = index # Assuming row order (1, 2, 3, etc.)
      @game_id_mapping[simplistic_id] = game.id
    end
  end

  def self.import_bet_options(data)
    raise "Games must be imported before Bet Options" if @game_id_mapping.nil?

    data.each do |row|
      next if row[0].to_i.zero? # Skip the header or invalid rows

      actual_game_id = @game_id_mapping[row[0].to_i] # Assuming column 0 is simplistic game ID
      BetOption.create!(
        game_id: actual_game_id,
        title: row[1], # Assuming column 1 is title
        payout: row[2], # Assuming column 2 is payout
        category: row[3] # Assuming column 3 is category
      )
    end
  end

  def self.update_bet_options_and_bets(games_data, bet_options_data)
    game_id_mapping = {}
    games_data.each_with_index do |row, index|
      next if index.zero? # Skip the header row

      home_team = Team.find_by(name: row[0]) # Assuming column 0 is home_team
      away_team = Team.find_by(name: row[1]) # Assuming column 1 is away_team
      next unless home_team && away_team

      game = Game.find_by(
        start_time: row[2], # Assuming column 2 is start_time
        home_team_id: home_team.id,
        away_team_id: away_team.id
      )
      next unless game

      simplistic_id = index
      game_id_mapping[simplistic_id] = game.id
    end

    bet_options_data.each do |row|
      simplistic_game_id = row[0].to_i # Assuming column 0 is simplistic game ID
      actual_game_id = game_id_mapping[simplistic_game_id]
      next unless actual_game_id

      bet_option = BetOption.find_by(game_id: actual_game_id, title: row[1]) # Assuming column 1 is title
      next unless bet_option

      unless row[4].nil? # Assuming column 4 is success
        success_status = row[4].to_i == 1
        bet_option.update!(success: success_status)

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
