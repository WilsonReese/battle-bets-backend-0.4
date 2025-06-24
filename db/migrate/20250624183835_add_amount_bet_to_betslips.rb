class AddAmountBetToBetslips < ActiveRecord::Migration[7.1]
  def change
    add_column :betslips, :amount_bet, :float, default: 0.0, null: false
  end
end
