class Users::ConfirmationsController < Devise::ConfirmationsController
  respond_to :json

  # GET /users/confirmation?confirmation_token=abcdef
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])

    if resource.errors.empty?
      render html: "<h1 style='margin-top:30px;'>Your account has been confirmed.</h1>".html_safe, status: :ok
    else
      render html: "<h1 style='margin-top:30px;'>#{resource.errors.full_messages.join(", ")}</h1>".html_safe
    end
  end
end