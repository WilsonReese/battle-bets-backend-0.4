# == Schema Information
#
# Table name: pool_memberships
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  pool_id    :integer          not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_pool_memberships_on_pool_id  (pool_id)
#  index_pool_memberships_on_user_id  (user_id)
#
# Foreign Keys
#
#  pool_id  (pool_id => pools.id)
#  user_id  (user_id => users.id)
#
class PoolMembership < ApplicationRecord
  belongs_to :user
  belongs_to :pool

  validates :user_id, uniqueness: { scope: :pool_id, message: "User is already a member of this pool" }
end
