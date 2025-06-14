# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    token = request.env['warden-jwt_auth.token']
    render json: {
      message: 'Logged in successfully.',
      token: token,
      confirmed: resource.confirmed? # ✅ use resource here
    }, status: :ok, headers: { 'Authorization': "Bearer #{token}" }
  end

  def respond_to_on_destroy
    render json: { message: 'Logged out successfully.' }, status: :ok
  end
end
