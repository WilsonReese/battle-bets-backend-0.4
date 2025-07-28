class CreateAnnouncements < ActiveRecord::Migration[7.1]
  def change
    create_table :announcements do |t|
      t.string :title, null: false
      t.text :paragraph, null: false
      t.string :link
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
