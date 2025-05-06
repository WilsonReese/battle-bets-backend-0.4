# == Schema Information
#
# Table name: league_seasons
#
#  id         :bigint           not null, primary key
#  start_week :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  pool_id    :bigint           not null
#  season_id  :bigint           not null
#
# Indexes
#
#  index_league_seasons_on_pool_id    (pool_id)
#  index_league_seasons_on_season_id  (season_id)
#
# Foreign Keys
#
#  fk_rails_...  (pool_id => pools.id)
#  fk_rails_...  (season_id => seasons.id)
#
class LeagueSeason < ApplicationRecord
  belongs_to :season
  belongs_to :pool
  has_many :battles, dependent: :destroy
  has_many :leaderboard_entries, dependent: :destroy
  
  validates :start_week, presence: true 
end
