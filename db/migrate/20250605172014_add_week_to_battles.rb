class AddWeekToBattles < ActiveRecord::Migration[7.1]
  def change
    add_column :battles, :week, :integer
  end
end
