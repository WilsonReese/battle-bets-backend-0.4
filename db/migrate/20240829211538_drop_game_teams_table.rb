class DropGameTeamsTable < ActiveRecord::Migration[7.1]
  def change
    drop_table :game_teams do |t|
      t.references :game, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.boolean :is_home, null: false, default: false
      t.timestamps
    end
  end
end
