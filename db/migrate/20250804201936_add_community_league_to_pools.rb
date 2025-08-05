class AddCommunityLeagueToPools < ActiveRecord::Migration[7.1]
  def change
    add_column :pools, :community_league, :boolean, 
              default: false,
              null: false
  end
end
