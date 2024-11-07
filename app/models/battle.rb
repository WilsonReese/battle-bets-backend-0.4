# == Schema Information
#
# Table name: battles
#
#  id         :integer          not null, primary key
#  end_date   :datetime
#  start_date :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  pool_id    :integer          not null
#
# Indexes
#
#  index_battles_on_pool_id  (pool_id)
#
# Foreign Keys
#
#  pool_id  (pool_id => pools.id)
#
class Battle < ApplicationRecord
  belongs_to :pool
  has_many :betslips, dependent: :destroy

  validates :start_date, :end_date, presence: true

  def betslip_count
    betslips.count
  end
end
