class AddBattlesLockedToGames < ActiveRecord::Migration[7.1]
  def change
    add_column :games, :battles_locked, :boolean, default: false, null: false
    add_index  :games, :battles_locked
  end
end
