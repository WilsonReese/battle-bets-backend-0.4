# == Schema Information
#
# Table name: announcements
#
#  id         :bigint           not null, primary key
#  active     :boolean          default(TRUE), not null
#  link       :string
#  paragraph  :text             not null
#  title      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Announcement < ApplicationRecord

  scope :live, -> { where(active: true)     }
  scope :recent, -> { order(created_at: :desc) }

  validates :title,     presence: true
  validates :paragraph, presence: true

end
