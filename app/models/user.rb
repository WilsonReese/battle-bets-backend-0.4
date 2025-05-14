# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  avatar                 :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  first_name             :string
#  jti                    :string           not null
#  last_name              :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  username               :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_jti                   (jti) UNIQUE
#  index_users_on_lower_username        (lower((username)::text)) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  
  # Direct Associations
  has_many :pool_memberships, dependent: :destroy
  has_many :leaderboard_entries, dependent: :destroy
  has_many :betslips, dependent: :destroy
  
  
  # Indirect Associations
  has_many :pools, through: :pool_memberships

  before_validation :downcase_username
  
  # Validations
  validates :username,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { in: 3..20 },
            format: { with: /\A[a-zA-Z_][a-zA-Z0-9_]*\z/, message: "can only contain letters, numbers, and underscores, and must start with a letter or underscore" }
  validate :password_complexity
  validates :first_name, presence: true
  validates :last_name, presence: true

  private

  def downcase_username
    self.username = username.downcase if username.present?
  end

  def password_complexity
    return if password.blank? # Let Devise handle presence

    if password.length < 8
      errors.add(:password, "must be at least 8 characters")
    end

    if password.include?(" ")
      errors.add(:password, "cannot contain spaces")
    end
  end
end
