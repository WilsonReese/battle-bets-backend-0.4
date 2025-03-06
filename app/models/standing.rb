# == Schema Information
#
# Table name: standings
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
#  index_standings_on_league_season_id  (league_season_id)
#  index_standings_on_user_id           (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (league_season_id => league_seasons.id)
#  fk_rails_...  (user_id => users.id)
#
class Standing < ApplicationRecord
  # Each Row in this table refers to a single "standing" - one user, one league season, and one total points for that season
  # All of them make the "standings" for that league season
  
  belongs_to :league_season
  belongs_to :user

  validates :total_points, presence: true
end
