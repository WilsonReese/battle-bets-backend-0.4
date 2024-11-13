class CreateBetOptions < ActiveRecord::Migration[7.1]
  def change
    create_table :bet_options do |t|
      t.string :title
      t.decimal :payout
      t.string :category
      t.references :game, null: false, foreign_key: true

      t.timestamps
    end
  end
end
