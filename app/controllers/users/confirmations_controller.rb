class Users::ConfirmationsController < Devise::ConfirmationsController
  respond_to :json

  # GET /users/confirmation?confirmation_token=abcdef
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])

    if resource.errors.empty?
      render json: { message: "Your email address has been successfully confirmed." }, status: :ok
    else
      render html: "<h1 style='text-align:center; margin-top:30px;'>#{resource.errors.full_messages.join(", ")}</h1>".html_safe
    end
  end
end