class Users::PasswordsController < Devise::PasswordsController
  respond_to :json

  # Called when the user requests a password reset
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)

    if successfully_sent?(resource)
      resource.update!(resetting_password: false) # ✅ your custom flag
      render json: { message: "Reset password instructions sent." }, status: :ok
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Called when reset link is clicked
  def edit
    self.resource = resource_class.with_reset_password_token(params[:reset_password_token])

    if resource && resource.persisted?
      resource.update!(
        resetting_password: true,
        resetting_password_set_at: Time.current,
        reset_password_token: nil,          # 🔐 Invalidate token
        reset_password_sent_at: nil         # 🔐 Clear timestamp too (optional)
      )
      render plain: "Password reset activated. Please return to the app."
    else
      render plain: "Invalid or expired token", status: :unprocessable_entity
    end
  end

  # Called from the app when the user sets their new password
  def update
    user = User.find_by(email: params[:email], resetting_password: true)

    if user.present?
      if user.resetting_password_set_at.blank? || user.resetting_password_set_at < 10.minutes.ago
        user.update!(resetting_password: false, resetting_password_set_at: nil)
        return render json: { error: "Password reset session expired. Please request a new link." }, status: :unauthorized
      end

      if user.update(password: params[:password], password_confirmation: params[:password_confirmation])
        user.update!(resetting_password: false, resetting_password_set_at: nil)
        render json: { message: "Password updated successfully." }, status: :ok
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: "Unauthorized or expired reset request" }, status: :unauthorized
    end
  end


  private

  def password_update_params
    params.require(:user).permit(:reset_password_token, :password, :password_confirmation)
  end
end