class CreateGameTeams < ActiveRecord::Migration[7.1]
  def change
    create_table :game_teams do |t|
      t.references :game, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.boolean :is_home

      t.timestamps
    end
  end
end
