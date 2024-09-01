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
end