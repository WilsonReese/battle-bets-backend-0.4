# == Schema Information
#
# Table name: bet_options
#
#  id         :bigint           not null, primary key
#  bet_flavor :integer
#  category   :string
#  long_title :string
#  payout     :decimal(, )
#  success    :boolean
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  game_id    :bigint           not null
#
# Indexes
#
#  index_bet_options_on_game_id  (game_id)
#
# Foreign Keys
#
#  fk_rails_...  (game_id => games.id)
#
class BetOption < ApplicationRecord
  belongs_to :game
  has_many :bets

  validates :title, presence: true
  validates :payout, numericality: { greater_than: 0 }
  validates :category, presence: true
  validates :bet_flavor, presence: true

  enum bet_flavor: {
    away_team_spread: 0,
    home_team_spread: 1,
    away_team_ml: 2,
    home_team_ml: 3,
    over: 4,
    under: 5,
    overtime: 6,
    first_team_to_score: 7,
    player_pass_tds: 8,
    player_pass_yds: 9,
    player_receptions: 10,
    player_reception_tds: 11,
    player_reception_yds: 12,
    player_rush_attempts: 13,
    player_rush_tds: 14,
    player_rush_yds: 15,
    player_sacks: 16
  }

  before_save :set_long_title

  private

  def set_long_title
    game = self.game
    self.long_title = "#{game.away_team.name} at #{game.home_team.name}: #{title}"
  end
end
