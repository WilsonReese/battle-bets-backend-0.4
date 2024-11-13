class CreateBetslips < ActiveRecord::Migration[7.1]
  def change
    create_table :betslips do |t|
      t.string :name
      t.references :user, null: false, foreign_key: true
      t.references :battle, null: false, foreign_key: true

      t.timestamps
    end
  end
end
