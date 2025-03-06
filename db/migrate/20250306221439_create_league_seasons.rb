class CreateLeagueSeasons < ActiveRecord::Migration[7.1]
  def change
    create_table :league_seasons do |t|
      t.references :season, null: false, foreign_key: true
      t.references :pool, null: false, foreign_key: true

      t.timestamps
    end
  end
end
