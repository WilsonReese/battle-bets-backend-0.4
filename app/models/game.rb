# == Schema Information
#
# Table name: games
#
#  id         :integer          not null, primary key
#  start_time :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Game < ApplicationRecord
    has_many :game_teams, dependent: :destroy
    has_many :bet_options, dependent: :destroy
    has_many :teams, through: :game_teams

    scope :within_date_range, ->(start_date, end_date) {
        where(start_time: start_date..end_date)
      }
end
