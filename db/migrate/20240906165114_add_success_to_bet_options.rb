class AddSuccessToBetOptions < ActiveRecord::Migration[7.1]
  def change
    add_column :bet_options, :success, :boolean, null: true
  end
end
