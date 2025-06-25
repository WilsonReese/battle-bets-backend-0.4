# == Schema Information
#
# Table name: games
#
#  id                    :bigint           not null, primary key
#  battles_locked        :boolean          default(FALSE), not null
#  start_time            :datetime
#  week                  :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  api_sports_io_game_id :string
#  away_team_id          :integer
#  espn_id               :string
#  home_team_id          :integer
#  odds_api_game_id      :string
#  season_id             :bigint           not null
#
# Indexes
#
#  index_games_on_api_sports_io_game_id  (api_sports_io_game_id) UNIQUE
#  index_games_on_battles_locked         (battles_locked)
#  index_games_on_season_id              (season_id)
#
# Foreign Keys
#
#  fk_rails_...  (away_team_id => teams.id)
#  fk_rails_...  (home_team_id => teams.id)
#  fk_rails_...  (season_id => seasons.id)
#
class Game < ApplicationRecord
  belongs_to :season
  has_many :bet_options, -> {order(:created_at)}, dependent: :destroy
  belongs_to :home_team, class_name: 'Team'
  belongs_to :away_team, class_name: 'Team'

  # validates :espn_id, uniqueness: true -- hard coded, temporarily disable

  scope :with_bet_options, -> {
    joins(:bet_options).distinct
  }

  scope :within_date_range, ->(start_date, end_date) {
      where(start_time: start_date..end_date)
    }
end
