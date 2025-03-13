class AddRankingToLeaderboardEntries < ActiveRecord::Migration[7.1]
  def change
    add_column :leaderboard_entries, :ranking, :integer, default: nil
  end
end
