class RemoveUniqueIndexFromApiSportsIoIdOnTeams < ActiveRecord::Migration[7.1]
  def change
    remove_index :teams, :api_sports_io_id
    add_index :teams, :api_sports_io_id  # without unique: true
  end
end
