# == Schema Information
#
# Table name: battles
#
#  id         :bigint           not null, primary key
#  end_date   :datetime
#  locked     :boolean          default(FALSE), not null
#  start_date :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  pool_id    :bigint           not null
#
# Indexes
#
#  index_battles_on_pool_id  (pool_id)
#
# Foreign Keys
#
#  fk_rails_...  (pool_id => pools.id)
#
class Battle < ApplicationRecord
  belongs_to :pool
  has_many :betslips, dependent: :destroy

  # Scopes
  scope :locked, -> { where(locked: true) }
  scope :unlocked, -> { where(locked: false) }

  validates :start_date, :end_date, presence: true
  validates :locked, inclusion: { in: [true, false] }

  def betslip_count
    betslips.submitted.count
  end

  def lock!
    update!(locked: true)
  end
end
