class AddLongTitleToBetOptions < ActiveRecord::Migration[7.1]
  def change
    add_column :bet_options, :long_title, :string
  end
end
