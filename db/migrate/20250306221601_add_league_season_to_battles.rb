class AddLeagueSeasonToBattles < ActiveRecord::Migration[7.1]
  def change
    add_reference :battles, :league_season, null: false, foreign_key: true
    remove_reference :battles, :pool, foreign_key: true
  end
end
