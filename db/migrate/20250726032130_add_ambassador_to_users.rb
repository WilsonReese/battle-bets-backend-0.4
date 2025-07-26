class AddAmbassadorToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :ambassador, :integer
  end
end
