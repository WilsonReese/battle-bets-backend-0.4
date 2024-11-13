# == Schema Information
#
# Table name: teams
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Team < ApplicationRecord
    has_many :home_games, class_name: 'Game', foreign_key: 'home_team_id', dependent: :nullify
    has_many :away_games, class_name: 'Game', foreign_key: 'away_team_id', dependent: :nullify
end
