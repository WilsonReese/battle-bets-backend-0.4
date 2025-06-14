# == Schema Information
#
# Table name: leaderboard_entries
#
#  id               :bigint           not null, primary key
#  ranking          :integer
#  total_points     :float            default(0.0)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  league_season_id :bigint           not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_leaderboard_entries_on_league_season_id              (league_season_id)
#  index_leaderboard_entries_on_league_season_id_and_user_id  (league_season_id,user_id) UNIQUE
#  index_leaderboard_entries_on_user_id                       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (league_season_id => league_seasons.id)
#  fk_rails_...  (user_id => users.id)
#
class LeaderboardEntry < ApplicationRecord  
  belongs_to :league_season
  belongs_to :user

  validates :total_points, presence: true

  # After save callback to trigger ranking updates
  after_save :update_rankings

  # Method to update rankings for entries in the same league season
  def update_rankings
    entries = league_season.leaderboard_entries.order(total_points: :desc)

    # Assign rankings based on total points
    current_rank = 0
    previous_points = nil
    rank_counter = 0

    entries.each do |entry|
      rank_counter += 1

      if entry.total_points != previous_points
        current_rank = rank_counter
      end

      entry.update_column(:ranking, current_rank)  # Use update_column to skip callbacks for performance
      previous_points = entry.total_points
    end
  end
end
