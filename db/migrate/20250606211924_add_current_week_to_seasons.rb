class AddCurrentWeekToSeasons < ActiveRecord::Migration[7.1]
  def change
    add_column :seasons, :current_week, :integer, null: false, default: 0
  end
end
