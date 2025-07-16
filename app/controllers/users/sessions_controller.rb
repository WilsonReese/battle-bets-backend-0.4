# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  respond_to :json

  # PUBLIC: override the sign-out action
  # If the token no longer maps to a real user, just return 200 OK
  def destroy
    unless current_user
      Rails.logger.warn "Logout called on missing user—skipping JWT revocation."
      return head :ok
    end

    # Otherwise, let Devise + devise-jwt revoke and then call respond_to_on_destroy
    super
  end

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
