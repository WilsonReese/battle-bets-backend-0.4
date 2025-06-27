# == Schema Information
#
# Table name: battles
#
#  id               :bigint           not null, primary key
#  current          :boolean          default(FALSE), not null
#  end_date         :datetime
#  locked           :boolean          default(FALSE), not null
#  start_date       :datetime
#  status           :integer          default("not_started"), not null
#  week             :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  league_season_id :bigint           not null
#
# Indexes
#
#  index_battles_on_league_season_id                (league_season_id)
#  index_battles_on_league_season_id_and_week       (league_season_id,week) UNIQUE
#  index_battles_on_league_season_id_where_current  (league_season_id) UNIQUE WHERE current
#
# Foreign Keys
#
#  fk_rails_...  (league_season_id => league_seasons.id)
#
class Battle < ApplicationRecord
  belongs_to :league_season
  has_many :betslips, dependent: :destroy

  enum status: { not_started: 0, in_progress: 1, completed: 2 }

  # Scopes
  scope :locked, -> { where(locked: true) }
  scope :unlocked, -> { where(locked: false) }

  validates :start_date, :end_date, presence: true
  validates :locked, inclusion: { in: [true, false] }
  validates :week, presence: true, uniqueness: { scope: :league_season_id }
  validate :only_one_in_progress_per_league_season, if: -> { in_progress? }
  validate :only_one_current_per_league_season, if: -> { current? }

  after_create :create_betslips_for_members

  def filled_out_betslip_count
    betslips.filled_out.count
  end

  def lock!
    update!(locked: true)
  end

  # app/models/battle.rb

  # def complete!
  #   ActiveRecord::Base.transaction do
  #     update!(status: :completed)

  #     # Sort the betslips in the battle by earnings
  #     betslips_with_earnings = betslips.to_a.sort_by { |b| -b.earnings }

  #     top_earnings = betslips_with_earnings.first&.earnings
  #     return if top_earnings.nil?

  #     betslips_with_earnings.each do |betslip|
  #       points = betslip.earnings == top_earnings ? 20 : 10

  #       entry = LeaderboardEntry.find_or_create_by!(
  #         user_id: betslip.user_id,
  #         league_season_id: league_season_id
  #       )

  #       # Increase the points on the leaderboard entry
  #       entry.increment!(:total_points, points)
        
  #       # Add league points to the betslip
  #       betslip.skip_locked_check = true
  #       betslip.update!(league_points: points)
  #     end
  #   end
  # end

  def complete!
    ActiveRecord::Base.transaction do
      update!(status: :completed)

      betslips_ranked = betslips.order(earnings: :desc, max_payout_remaining: :desc)
      size            = betslips_ranked.size

      rank = 0
      prev = nil
      updated_entries = {}

      betslips_ranked.each_with_index do |bs, idx|
        if prev&.earnings != bs.earnings || prev&.max_payout_remaining != bs.max_payout_remaining
          rank = idx + 1
        end
        prev = bs

        points = SeasonScoringService.points_for(rank, size)

        entry = LeaderboardEntry.find_or_initialize_by(
          user_id: bs.user_id,
          league_season_id: league_season_id
        )
        entry.total_points ||= 0
        entry.total_points += points
        entry.skip_ranking_update = true  # ⛔️ Prevent callback
        updated_entries[entry.user_id] = entry

        bs.update!(league_points: points, skip_locked_check: true)
      end

      updated_entries.values.each(&:save!)

      # ✅ Call ranking update once
      LeaderboardEntry.update_rankings_for(league_season_id)
    end
  end

  def only_one_in_progress_per_league_season
    existing = Battle.where(
      league_season_id: league_season_id,
      status: :in_progress
    ).where.not(id: id).exists?

    if existing
      errors.add(:status, "can only be 'in_progress' for one battle at a time per league season")
    end
  end

  def only_one_current_per_league_season
    if Battle.where(league_season_id: league_season_id, current: true).where.not(id: id).exists?
      errors.add(:current, "can only be true for one battle per league season")
    end
  end


  private

  def create_betslips_for_members
    return if locked? # THIS IS ONLY FOR SAMPLE DATA - Skip betslip creation if battle is locked

    league_season.pool.users.find_each do |user|
      betslips.create!(user: user)
    end
  end
end
