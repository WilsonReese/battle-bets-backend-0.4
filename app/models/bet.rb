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
  validates :to_win_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
