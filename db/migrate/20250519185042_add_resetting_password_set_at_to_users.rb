class AddResettingPasswordSetAtToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :resetting_password_set_at, :datetime
  end
end
