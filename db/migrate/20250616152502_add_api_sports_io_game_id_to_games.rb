class AddApiSportsIoGameIdToGames < ActiveRecord::Migration[7.1]
  def change
    add_column :games, :api_sports_io_game_id, :string
    add_index :games, :api_sports_io_game_id, unique: true
  end
end
