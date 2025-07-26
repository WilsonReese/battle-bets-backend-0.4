class AddFavoriteTeamToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :favorite_team_id, :integer
    add_index :users, :favorite_team_id
  end
end
