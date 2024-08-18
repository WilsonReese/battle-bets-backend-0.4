# == Schema Information
#
# Table name: bets
#
#  id            :integer          not null, primary key
#  bet_amount    :decimal(, )
#  to_win_amount :decimal(, )
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  bet_option_id :integer          not null
#  betslip_id    :integer          not null
#
# Indexes
#
#  index_bets_on_bet_option_id  (bet_option_id)
#  index_bets_on_betslip_id     (betslip_id)
#
# Foreign Keys
#
#  bet_option_id  (bet_option_id => bet_options.id)
#  betslip_id     (betslip_id => betslips.id)
#
class Bet < ApplicationRecord
  belongs_to :betslip
  belongs_to :bet_option

  validates :bet_amount, presence: true, numericality: { greater_than: 0 }
  validates :to_win_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_save :calculate_to_win_amount
  after_save :ensure_to_win_amount_is_not_nil

  private

  def calculate_to_win_amount
    self.to_win_amount = bet_amount * bet_option.payout
  end
  
  def ensure_to_win_amount_is_not_nil
    if to_win_amount.nil?
      raise "to_win_amount should not be nil after saving Bet"
    end
  end
end