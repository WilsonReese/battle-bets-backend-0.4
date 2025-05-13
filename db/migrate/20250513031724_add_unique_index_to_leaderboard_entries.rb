class AddUniqueIndexToLeaderboardEntries < ActiveRecord::Migration[7.1]
  def change
    add_index :leaderboard_entries, [:league_season_id, :user_id], unique: true
  end
end
