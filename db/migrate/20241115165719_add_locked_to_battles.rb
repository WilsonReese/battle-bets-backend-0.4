class AddLockedToBattles < ActiveRecord::Migration[7.1]
  def change
    add_column :battles, :locked, :boolean, default: false, null: false
  end
end
