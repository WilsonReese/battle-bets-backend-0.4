# == Schema Information
#
# Table name: teams
#
#  id                 :bigint           not null, primary key
#  conference         :string
#  long_name          :string
#  long_name_odds_api :string
#  name               :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  api_sports_io_id   :integer
#  espn_id            :integer
#
# Indexes
#
#  index_teams_on_api_sports_io_id  (api_sports_io_id)
#
class Team < ApplicationRecord
  has_many :home_games, class_name: 'Game', foreign_key: 'home_team_id', dependent: :nullify
  has_many :away_games, class_name: 'Game', foreign_key: 'away_team_id', dependent: :nullify

  has_many :fans,
          class_name: "User",
          foreign_key: :favorite_team_id,
          dependent: :nullify

  validates :name, presence: true, uniqueness: true

  def self.eligible_for_import
    where(conference: ["SEC", "ACC", "Big Ten", "Big 12"]).or(where(name: "Notre Dame"))
  end
end
