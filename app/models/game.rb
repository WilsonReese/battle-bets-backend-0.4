# == Schema Information
#
# Table name: games
#
#  id           :bigint           not null, primary key
#  start_time   :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  away_team_id :integer
#  home_team_id :integer
#
# Foreign Keys
#
#  fk_rails_...  (away_team_id => teams.id)
#  fk_rails_...  (home_team_id => teams.id)
#
class Game < ApplicationRecord
    has_many :bet_options, dependent: :destroy
    belongs_to :home_team, class_name: 'Team'
    belongs_to :away_team, class_name: 'Team'

    scope :within_date_range, ->(start_date, end_date) {
        where(start_time: start_date..end_date)
      }
end
