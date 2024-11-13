class AddStatusAndLockedToBetslips < ActiveRecord::Migration[7.1]
  def change
    add_column :betslips, :status, :string, default: "created", null: false
    add_column :betslips, :locked, :boolean, default: false, null: false
  end
end
