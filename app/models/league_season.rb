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
  validate :start_week_must_be_after_current_week, on: [:create, :update] 

  after_create :create_leaderboard_entries_for_all_members
  after_create :generate_battles

  def has_started?
    season.present? && start_week.present? && start_week <= season.current_week.to_i
  end

  def create_leaderboard_entries_for_all_members
    pool.pool_memberships.find_each do |membership|
      LeaderboardEntry.find_or_create_by!(league_season: self, user: membership.user) do |entry|
        entry.total_points = 0
        entry.ranking = nil
      end
    end
  end

    private

  def start_week_must_be_after_current_week
    return if season.blank? || start_week.blank?

    if season.current_week.present? && start_week <= season.current_week
      errors.add(:start_week, "must be after the current week (#{season.current_week}) of the season.")
    end
  end

  def generate_battles
    base_date = Date.new(2025, 8, 24) # Sunday of Week 1

    (1..14).each do |week_number|
      start_date = base_date + (week_number - 1).weeks
      end_date = start_date + 6.days + 23.hours + 59.minutes + 59.seconds

      battles.create!(
        week: week_number,
        start_date: start_date.beginning_of_day,
        end_date: end_date.end_of_day,
        status: :not_started,
        current: false,
        locked: false
      )
    end
  end
end
