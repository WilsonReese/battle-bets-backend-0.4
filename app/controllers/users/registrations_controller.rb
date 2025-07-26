# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  private

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :username, :first_name, :last_name, :avatar, :favorite_team_id)
  end

  def account_update_params
    params.require(:user).permit(:email, :password, :password_confirmation, :current_password, :username, :first_name, :last_name, :avatar, :favorite_team_id)
  end

  def respond_with(resource, _opts = {})
    register_success && return if resource.persisted?

    register_failed
  end

  def register_success
    render json: { message: 'Signed up successfully.' }, status: :ok
  end

  def register_failed
    render json: { errors: resource.errors }, status: :unprocessable_entity
  end
end
