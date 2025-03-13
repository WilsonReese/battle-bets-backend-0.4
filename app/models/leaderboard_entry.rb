# == Schema Information
#
# Table name: leaderboard_entries
#
#  id               :bigint           not null, primary key
#  total_points     :float            default(0.0)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  league_season_id :bigint           not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_leaderboard_entries_on_league_season_id  (league_season_id)
#  index_leaderboard_entries_on_user_id           (user_id)
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
end
