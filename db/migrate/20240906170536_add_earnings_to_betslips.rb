class AddEarningsToBetslips < ActiveRecord::Migration[7.1]
  def change
    add_column :betslips, :earnings, :float, default: 0.0, null: false
  end
end
