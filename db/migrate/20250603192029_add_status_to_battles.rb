class AddStatusToBattles < ActiveRecord::Migration[7.1]
  def change
    add_column :battles, :status, :integer, default: 0, null: false
  end
end
