class UsersController < ApplicationController
  before_action :authenticate_user!

  def current
    render json: {
      id: current_user.id,
      email: current_user.email,
      username: current_user.username,
      confirmed: current_user.confirmed?,
      first_name: current_user.first_name,
      last_name: current_user.last_name
    }
  end
end