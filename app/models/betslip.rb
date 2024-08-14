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

  validates :name, presence: true, length: { maximum: 255 }

  before_validation :set_default_name, on: :create

  private

  def set_default_name
    if name.blank? && user.present?
      self.name = "#{user.username}'s Bets"
    end
  end
end
