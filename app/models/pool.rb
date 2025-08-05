# == Schema Information
#
# Table name: pools
#
#  id               :bigint           not null, primary key
#  community_league :boolean          default(FALSE), not null
#  invite_token     :string
#  name             :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_pools_on_invite_token  (invite_token) UNIQUE
#
class Pool < ApplicationRecord
    # Associations
    has_many :pool_memberships, dependent: :destroy
    has_many :users, through: :pool_memberships
    has_many  :league_seasons, dependent: :destroy


    # Need to build out a way for the week selected to be accepted

    # Validations
    validates :name, presence: true

    before_create :generate_invite_token

    def sorted_memberships
      pool_memberships
        .includes(:user)
        .order(is_commissioner: :desc, created_at: :desc)
    end

    private

    def generate_invite_token
      # Generate a short, URL-safe token
      self.invite_token = SecureRandom.urlsafe_base64(10)
    end

end
