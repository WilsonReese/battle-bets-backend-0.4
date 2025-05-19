class UsersController < ApplicationController
  before_action :authenticate_user!, only: %i[current]

  def current
    render json: {
      id: current_user.id,
      email: current_user.email,
      username: current_user.username,
      confirmed: current_user.confirmed?,
      first_name: current_user.first_name,
      last_name: current_user.last_name,
      resetting_password: current_user.resetting_password
    }
  end

  def reset_status
    user = User.find_by(email: params[:email])
    if user
      render json: { resetting_password: user.resetting_password }
    else
      render json: { resetting_password: false }, status: :not_found
    end
  end
end
