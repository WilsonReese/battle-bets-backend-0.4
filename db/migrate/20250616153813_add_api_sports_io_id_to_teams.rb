class AddApiSportsIoIdToTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :api_sports_io_id, :integer
    add_index :teams, :api_sports_io_id, unique: true
  end
end
