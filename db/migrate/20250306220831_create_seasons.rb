class CreateSeasons < ActiveRecord::Migration[7.1]
  def change
    create_table :seasons do |t|
      t.integer :year, null: false
      t.datetime :start_date, null: false
      t.datetime :end_date, null: false

      t.timestamps
    end
  end
end
