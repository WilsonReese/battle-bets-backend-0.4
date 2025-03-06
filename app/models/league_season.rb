# == Schema Information
#
# Table name: league_seasons
#
#  id         :bigint           not null, primary key
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
  has_many :standings, dependent: :destroy # each row of standings is a single record for a user's score for the season (aka one standing, and many standings)
end
