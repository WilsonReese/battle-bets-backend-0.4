class AddLeaguePointsToBetslips < ActiveRecord::Migration[7.1]
  def change
    add_column :betslips, :league_points, :float, default: nil
  end
end
