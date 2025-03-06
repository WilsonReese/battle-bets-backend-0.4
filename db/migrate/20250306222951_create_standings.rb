class CreateStandings < ActiveRecord::Migration[7.1]
  def change
    create_table :standings do |t|
      t.references :league_season, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.float :total_points, default: 0

      t.timestamps
    end
  end
end
