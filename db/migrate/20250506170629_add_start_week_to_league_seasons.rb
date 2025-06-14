class AddStartWeekToLeagueSeasons < ActiveRecord::Migration[7.1]
  def change
    add_column :league_seasons, :start_week, :integer
  end
end
