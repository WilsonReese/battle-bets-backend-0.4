# == Schema Information
#
# Table name: betslips
#
#  id         :integer          not null, primary key
#  locked     :boolean          default(FALSE), not null
#  name       :string
#  status     :string           default("created"), not null
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

  has_many  :bets, dependent: :destroy

  enum status: { created: "created", submitted: "submitted", completed: "completed" }

  validates :name, length: { maximum: 255 }
  validates :status, exclusion: { in: %w(completed), message: "cannot be set to completed manually" }, on: :update
  validates :status, presence: true
  validates :locked, inclusion: { in: [true, false] }

  before_create :set_default_status
  before_update :ensure_not_locked, if: :locked?

  private

  def set_default_status
    self.status ||= "created"
  end

  def ensure_not_locked
    if locked?
      errors.add(:status, "cannot be changed. The betslip is locked.")
      throw(:abort)
    end
  end

  # I may want to make the name be set as a default to "Username's Bets"
  # But right now, it was causing me issues, so I will just allow the name to be null and not worry about a default
  # I can come back to this

end
