class AddBetFlavorToBetOptions < ActiveRecord::Migration[7.1]
  def change
    add_column :bet_options, :bet_flavor, :integer
  end
end
