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
    has_many  :battles, dependent: :destroy

    # I don't think I am going to use these 
    # has_many :bet_slips, dependent: :destroy
    # has_many :weekly_competitions, dependent: :destroy 

    # Validations
    validates :name, presence: true, uniqueness: true

end
