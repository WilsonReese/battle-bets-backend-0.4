# == Schema Information
#
# Table name: betslips
#
#  id                   :bigint           not null, primary key
#  amount_bet           :float            default(0.0), not null
#  earnings             :float            default(0.0), not null
#  league_points        :float
#  locked               :boolean          default(FALSE), not null
#  max_payout_remaining :float            default(0.0), not null
#  name                 :string
#  status               :string           default("created"), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  battle_id            :bigint           not null
#  user_id              :bigint           not null
#
# Indexes
#
#  index_betslips_on_battle_id  (battle_id)
#  index_betslips_on_user_id    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (battle_id => battles.id)
#  fk_rails_...  (user_id => users.id)
#
class Betslip < ApplicationRecord
  belongs_to :user
  belongs_to :battle

  has_many  :bets, dependent: :destroy

  enum status: { created: "created", filled_out: "filled_out", completed: "completed" }

  scope :created, -> { where(status: "created") }
  scope :filled_out, -> { where(status: "filled_out") }

  attr_accessor :skip_locked_check

  validates :name, length: { maximum: 255 }
  validates :status, exclusion: { in: %w(completed), message: "cannot be set to completed manually" }, on: :update
  validates :status, presence: true
  validates :locked, inclusion: { in: [true, false] }
  validates :user_id, uniqueness: { scope: :battle_id, message: "already has a betslip for this battle" }
  validate :battle_not_locked, on: :create

  before_create :set_default_status
  before_create :set_default_name
  before_update :ensure_not_locked, unless: -> { skip_locked_check }

  def calculate_earnings
    return unless persisted? && !destroyed?

    self.earnings = bets.sum { |bet| bet.amount_won.to_f }

    unless save
      Rails.logger.error "Failed to save betslip #{id} during earnings calc: #{errors.full_messages.join(', ')}"
    end
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

  def recalculate_amount_bet!
    update!(amount_bet: bets.sum(:bet_amount))
  end
  
  private

  def set_default_status
    self.status ||= "created"
  end

  def set_default_name
    if name.blank? && user
      self.name = "#{user.username}"
    end
  end

  def ensure_not_locked
    if locked?
      errors.add(:status, "cannot be changed. The betslip is locked.")
      throw(:abort)
    end
  end

  def battle_not_locked
    if battle.locked?
      errors.add(:base, "Cannot create a betslip for a locked battle.")
    end
  end

end
