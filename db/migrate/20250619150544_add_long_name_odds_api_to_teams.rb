class AddLongNameOddsApiToTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :long_name_odds_api, :string
  end
end
