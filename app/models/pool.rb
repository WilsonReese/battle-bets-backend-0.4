# == Schema Information
#
# Table name: pools
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Pool < ApplicationRecord
    # Associations
    has_many :pool_memberships, dependent: :destroy
    has_many :users, through: :pool_memberships
    has_many  :league_seasons, dependent: :destroy


    # Need to build out a way for the week selected to be accepted

    # I don't think I am going to use these 
    # has_many :bet_slips, dependent: :destroy
    # has_many :weekly_competitions, dependent: :destroy 

    # Validations
    validates :name, presence: true, uniqueness: true # do we need a unique name??

    # after_create :create_league_season

    # private

    # def create_league_season
    #   season = Season.find_by(year: 2024)
    #   return unless season && start_week.present?
  
    #   league_seasons.create(start_week: start_week, season: season)
    # end

end
