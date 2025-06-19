class AddOddsApiGameIdToGames < ActiveRecord::Migration[7.1]
  def change
    add_column :games, :odds_api_game_id, :string
  end
end
