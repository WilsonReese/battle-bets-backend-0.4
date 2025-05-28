# == Schema Information
#
# Table name: battles
#
#  id               :bigint           not null, primary key
#  end_date         :datetime
#  locked           :boolean          default(FALSE), not null
#  start_date       :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  league_season_id :bigint           not null
#
# Indexes
#
#  index_battles_on_league_season_id  (league_season_id)
#
# Foreign Keys
#
#  fk_rails_...  (league_season_id => league_seasons.id)
#
class Battle < ApplicationRecord
  belongs_to :league_season
  has_many :betslips, dependent: :destroy

  # Scopes
  scope :locked, -> { where(locked: true) }
  scope :unlocked, -> { where(locked: false) }

  validates :start_date, :end_date, presence: true
  validates :locked, inclusion: { in: [true, false] }

  after_create :create_betslips_for_members

  def filled_out_betslip_count
    betslips.filled_out.count
  end

  def lock!
    update!(locked: true)
  end

  private

  def create_betslips_for_members
    return if locked? # THIS IS ONLY FOR SAMPLE DATA - Skip betslip creation if battle is locked

    league_season.pool.users.find_each do |user|
      betslips.create!(user: user)
    end
  end
end
