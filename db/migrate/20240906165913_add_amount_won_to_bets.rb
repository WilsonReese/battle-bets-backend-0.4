class AddAmountWonToBets < ActiveRecord::Migration[7.1]
  def change
    add_column :bets, :amount_won, :float, null: true
  end
end
