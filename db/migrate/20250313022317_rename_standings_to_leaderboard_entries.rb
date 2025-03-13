class RenameStandingsToLeaderboardEntries < ActiveRecord::Migration[7.1]
  def change
    rename_table :standings, :leaderboard_entries
  end
end
