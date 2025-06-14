class AddInviteTokenToPools < ActiveRecord::Migration[7.1]
  def change
    add_column :pools, :invite_token, :string
    add_index :pools, :invite_token, unique: true
  end
end
