class CreateBets < ActiveRecord::Migration[7.1]
  def change
    create_table :bets do |t|
      t.references :betslip, null: false, foreign_key: true
      t.references :bet_option, null: false, foreign_key: true
      t.decimal :bet_amount
      t.decimal :to_win_amount

      t.timestamps
    end
  end
end
