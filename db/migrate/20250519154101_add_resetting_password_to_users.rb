class AddResettingPasswordToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :resetting_password, :boolean, default: false
  end
end
