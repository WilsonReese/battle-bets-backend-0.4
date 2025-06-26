# == Schema Information
#
# Table name: bets
#
#  id            :bigint           not null, primary key
#  amount_won    :float
#  bet_amount    :decimal(, )
#  to_win_amount :decimal(, )
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  bet_option_id :bigint           not null
#  betslip_id    :bigint           not null
#
# Indexes
#
#  index_bets_on_bet_option_id  (bet_option_id)
#  index_bets_on_betslip_id     (betslip_id)
#
# Foreign Keys
#
#  fk_rails_...  (bet_option_id => bet_options.id)
#  fk_rails_...  (betslip_id => betslips.id)
#
class Bet < ApplicationRecord
  belongs_to :betslip
  belongs_to :bet_option

  attr_accessor :skip_locked_check

  validates :bet_amount, presence: true, numericality: { greater_than: 0 }
  validates :to_win_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :bet_option_id, uniqueness: { 
    scope: :betslip_id, 
    message: "This bet option is already added to the betslip" 
  }

  # I added a line here so I would have something to commit.

  before_save :calculate_to_win_amount
  before_save :calculate_amount_won
  before_save :ensure_betslip_not_locked, unless: -> { skip_locked_check }
  after_save :ensure_to_win_amount_is_not_nil

  after_save :update_betslip_earnings
  after_destroy :update_betslip_earnings

  after_save :update_betslip_max_payout_remaining
  after_destroy :update_betslip_max_payout_remaining

  after_save    :update_betslip_budget
  after_destroy :update_betslip_budget

  def recompute_amount_won!    
    # 1️⃣ skip the “betslip locked” guard for this programmatic update
    self.skip_locked_check  = true          # skip check on this Bet
    betslip.skip_locked_check = true        # skip check on the Betslip callbacks, too

    # 2️⃣ re-compute amount_won
    self.amount_won =
      case bet_option.success
      when nil   then nil
      when true  then to_win_amount
      when false then 0
      end

    save!                                     # after_save callbacks still run
  ensure
    # 3️⃣ clean up so normal validations work elsewhere
    self.skip_locked_check = false
    betslip.skip_locked_check = false
  end

  private

  def calculate_to_win_amount
    self.to_win_amount = bet_amount * bet_option.payout
  end

  def calculate_amount_won
    self.amount_won =
      case bet_option.success
      when nil   then nil
      when true  then to_win_amount
      when false then 0
    end
  end

  def update_betslip_earnings
    betslip.calculate_earnings
  end

  def update_betslip_max_payout_remaining
    Rails.logger.info "update_betslip_max_payout_remaining triggered"
    betslip.calculate_max_payout_remaining
  end
  
  def ensure_to_win_amount_is_not_nil
    if to_win_amount.nil?
      raise "to_win_amount should not be nil after saving Bet"
    end
  end

  def ensure_betslip_not_locked
    if betslip.locked?
      errors.add(:base, "Cannot create or update a bet in a locked betslip.")
      throw(:abort)
    end
  end

  # This is for updating the amount a user bet in a given betslip
  def update_betslip_budget
    betslip.recalculate_amount_bet!
  end
end
