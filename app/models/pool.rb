# == Schema Information
#
# Table name: pools
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Pool < ApplicationRecord
    # Associations
    # has_many :pool_memberships, dependent: :destroy
    # has_many :users, through: :pool_memberships
    # has_many :bet_slips, dependent: :destroy
    # has_many :weekly_competitions, dependent: :destroy

    # Validations
    validates :name, presence: true, uniqueness: true

end
