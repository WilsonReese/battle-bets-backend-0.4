class AddHomeAndAwayTeamToGames < ActiveRecord::Migration[7.1]
  def change
    add_column :games, :home_team_id, :integer
    add_column :games, :away_team_id, :integer

    add_foreign_key :games, :teams, column: :home_team_id
    add_foreign_key :games, :teams, column: :away_team_id
  end
end
