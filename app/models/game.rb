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
    # has_many :game_teams, dependent: :destroy
    has_many :bet_options, dependent: :destroy
end
