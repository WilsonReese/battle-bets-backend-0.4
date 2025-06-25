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
  after_create :create_betslip_if_battle_in_progress
  before_destroy :remove_leaderboard_entries
  before_destroy :destroy_betslips_for_pool

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

  def remove_leaderboard_entries
    pool.league_seasons.each do |season|
      LeaderboardEntry.where(user: user, league_season: season).destroy_all
    end
  end

  def destroy_betslips_for_pool
    # 1. Nuke bets first so no FK complaints in some DB setups
    Bet.joins(betslip: { battle: { league_season: :pool } })
      .where(betslips: { user_id: user_id }, pools: { id: pool_id })
      .delete_all

    # 2. Now nuke the betslips
    Betslip
      .joins(battle: { league_season: :pool })
      .where(user_id: user_id, pools: { id: pool_id })
      .delete_all
  end

  def create_betslip_if_battle_in_progress
    league_season = pool.league_seasons.find_by(season: Season.current)

    return unless league_season

    current_battle = league_season.battles.find_by(current: true)

    return unless current_battle && !current_battle.locked?

    current_battle.betslips.find_or_create_by!(user: user)
  end

end
