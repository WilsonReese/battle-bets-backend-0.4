class AddIsCommissionerToPoolMemberships < ActiveRecord::Migration[7.1]
  def change
    add_column :pool_memberships, :is_commissioner, :boolean, default: false, null: false
  end
end
