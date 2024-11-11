# == Schema Information
#
# Table name: betslips
#
#  id                   :integer          not null, primary key
#  earnings             :float            default(0.0), not null
#  locked               :boolean          default(FALSE), not null
#  max_payout_remaining :float            default(0.0), not null
#  name                 :string
#  status               :string           default("created"), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  battle_id            :integer          not null
#  user_id              :integer          not null
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

  scope :submitted, -> { where(status: "submitted") }

  attr_accessor :skip_locked_check

  validates :name, length: { maximum: 255 }
  validates :status, exclusion: { in: %w(completed), message: "cannot be set to completed manually" }, on: :update
  validates :status, presence: true
  validates :locked, inclusion: { in: [true, false] }
  validates :user_id, uniqueness: { scope: :battle_id, message: "already has a betslip for this battle" }

  before_create :set_default_status
  before_create :set_default_name
  before_update :ensure_not_locked, unless: -> { skip_locked_check }

  def calculate_earnings
    self.earnings = bets.sum { |bet| bet.amount_won.to_f }
    save!
  end

  def calculate_max_payout_remaining
    # Sum all bets where amount_won is set (including zero amounts for lost bets)
    won_amounts = bets.where.not(amount_won: nil).sum(:amount_won)
    
    # Sum potential winnings for unsettled bets (where amount_won is nil)
    potential_win = bets.where(amount_won: nil).sum(:to_win_amount)
    
    # Update max_payout_remaining
    self.max_payout_remaining = won_amounts + potential_win
    Rails.logger.info "Calculated max_payout_remaining for Betslip #{id}: #{max_payout_remaining}"
      # Attempt to save and log any validation errors
    if save
      Rails.logger.info "Betslip #{id} successfully saved with max_payout_remaining: #{max_payout_remaining}"
    else
      Rails.logger.error "Failed to save Betslip #{id}: #{errors.full_messages.join(', ')}"
    end
  end
  
  private

  def set_default_status
    self.status ||= "created"
  end

  def set_default_name
    if name.blank? && user
      self.name = "#{user.first_name} #{user.last_name}'s Bets"
    end
  end

  def ensure_not_locked
    if locked?
      errors.add(:status, "cannot be changed. The betslip is locked.")
      throw(:abort)
    end
  end


end
