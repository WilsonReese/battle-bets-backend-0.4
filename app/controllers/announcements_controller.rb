class AnnouncementsController < ApplicationController
  # GET /announcements
  def index
    announcement = Announcement.live.recent.first

    if announcement
      render json: announcement.as_json(only: %i[id title paragraph link created_at active])
    else
      render json: {}, status: :no_content
    end
  end
end