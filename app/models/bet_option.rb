# == Schema Information
#
# Table name: bet_options
#
#  id         :integer          not null, primary key
#  category   :string
#  long_title :string
#  payout     :decimal(, )
#  success    :boolean
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  game_id    :integer          not null
#
# Indexes
#
#  index_bet_options_on_game_id  (game_id)
#
# Foreign Keys
#
#  game_id  (game_id => games.id)
#
class BetOption < ApplicationRecord
  belongs_to :game
  has_many :bets

  validates :title, presence: true
  validates :payout, numericality: { greater_than: 0 }
  validates :category, presence: true

  before_save :set_long_title

  private

  def set_long_title
    game = self.game
    self.long_title = "#{game.away_team.name} at #{game.home_team.name}: #{title}"
  end
end
