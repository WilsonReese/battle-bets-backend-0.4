# == Schema Information
#
# Table name: pool_memberships
#
#  id              :bigint           not null, primary key
#  is_commissioner :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  pool_id         :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_pool_memberships_on_pool_id  (pool_id)
#  index_pool_memberships_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (pool_id => pools.id)
#  fk_rails_...  (user_id => users.id)
#
class PoolMembership < ApplicationRecord
  belongs_to :user
  belongs_to :pool

  validates :user_id, uniqueness: { scope: :pool_id, message: "User is already a member of this pool" }

  after_create :create_leaderboard_entries_for_existing_seasons

  def can_be_demoted?
    return true unless is_commissioner

    other_commissioners_exist = pool.pool_memberships
      .where(is_commissioner: true)
      .where.not(id: id)
      .exists?

    other_commissioners_exist
  end

  private

  def create_leaderboard_entries_for_existing_seasons
    pool.league_seasons.find_each do |season|
      LeaderboardEntry.find_or_create_by!(league_season: season, user: user) do |entry|
        entry.total_points = 0
        entry.ranking = nil
        entry.update_rankings if entry.persisted?
      end
    end
  end

end
