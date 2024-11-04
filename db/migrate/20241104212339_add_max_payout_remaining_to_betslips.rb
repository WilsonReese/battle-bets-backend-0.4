class AddMaxPayoutRemainingToBetslips < ActiveRecord::Migration[7.1]
  def change
    add_column :betslips, :max_payout_remaining, :float, default: 0.0, null: false
  end
end
