class RemoveCompletedFromBattles < ActiveRecord::Migration[7.1]
  def change
    remove_column :battles, :completed, :boolean
  end
end
