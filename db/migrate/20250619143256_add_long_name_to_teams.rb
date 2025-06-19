class AddLongNameToTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :long_name, :string
  end
end
