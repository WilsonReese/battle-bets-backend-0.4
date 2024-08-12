class CreatePoolMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :pool_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :pool, null: false, foreign_key: true

      t.timestamps
    end
  end
end
