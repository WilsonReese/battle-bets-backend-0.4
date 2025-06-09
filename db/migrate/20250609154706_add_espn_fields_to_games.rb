class AddEspnFieldsToGames < ActiveRecord::Migration[7.1]
  def change
    add_column :games, :espn_id, :string
    add_column :games, :week, :integer
    add_reference :games, :season, null: false, foreign_key: true
  end
end
