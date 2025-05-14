class AddUniqueIndexToUsersOnLowerUsername < ActiveRecord::Migration[7.1]
  def up
    remove_index :users, :username if index_exists?(:users, :username)
    add_index :users, 'LOWER(username)', unique: true, name: 'index_users_on_lower_username'
  end

  def down
    remove_index :users, name: 'index_users_on_lower_username'
    add_index :users, :username, unique: true
  end
end
