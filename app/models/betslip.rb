# == Schema Information
#
# Table name: betslips
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  battle_id  :integer          not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_betslips_on_battle_id  (battle_id)
#  index_betslips_on_user_id    (user_id)
#
# Foreign Keys
#
#  battle_id  (battle_id => battles.id)
#  user_id    (user_id => users.id)
#
class Betslip < ApplicationRecord
  belongs_to :user
  belongs_to :battle

  validates :name, length: { maximum: 255 }

  # I may want to make the name be set as a default to "Username's Bets"
  # But right now, it was causing me issues, so I will just allow the name to be null and not worry about a default
  # I can come back to this

end
