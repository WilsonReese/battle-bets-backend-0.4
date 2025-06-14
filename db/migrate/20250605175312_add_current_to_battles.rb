class AddCurrentToBattles < ActiveRecord::Migration[7.1]
  def change
    add_column :battles, :current, :boolean, default: false, null: false
    add_index :battles, [:league_season_id], where: "current", unique: true, name: "index_battles_on_league_season_id_where_current"
  end
end
