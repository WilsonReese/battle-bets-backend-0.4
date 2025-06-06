# == Schema Information
#
# Table name: seasons
#
#  id           :bigint           not null, primary key
#  current_week :integer          default(0), not null
#  end_date     :datetime         not null
#  start_date   :datetime         not null
#  year         :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Season < ApplicationRecord
  has_many :league_seasons, dependent: :destroy
  validates :year, presence: true, uniqueness: true
  validates :current_week, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
