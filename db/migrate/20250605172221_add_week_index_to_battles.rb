class AddWeekIndexToBattles < ActiveRecord::Migration[7.1]
  def change
    add_index :battles, [:league_season_id, :week], unique: true
  end
end
