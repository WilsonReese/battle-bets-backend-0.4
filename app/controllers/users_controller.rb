class UsersController < ApplicationController
  before_action :authenticate_user!, only: %i[current update_profile change_password destroy]

  def current
    favorite_team = current_user.favorite_team
    render json: {
      id: current_user.id,
      email: current_user.email,
      username: current_user.username,
      confirmed: current_user.confirmed?,
      first_name: current_user.first_name,
      last_name: current_user.last_name,
      resetting_password: current_user.resetting_password,
      created_at: current_user.created_at,
      favorite_team_id: current_user.favorite_team_id,
      favorite_team: favorite_team && { id: favorite_team.id, name: favorite_team.name }
    }
  end

  def update_profile
    if current_user.update(profile_params)
      render json: current_user
    else
      render json: { errors: current_user.errors }, status: :unprocessable_entity
    end
  end

  def reset_status
    user = User.find_by(email: params[:email])
    if user
      render json: { resetting_password: user.resetting_password }
    else
      render json: { resetting_password: false }, status: :not_found
    end
  end

  def change_password
    if current_user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      render json: { message: "Password updated successfully." }, status: :ok
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

    # DELETE /user
  def destroy
    if current_user.destroy
      head :no_content
    else
      render json: { errors: current_user.errors.full_messages },
             status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :username, :favorite_team_id)
  end
end
