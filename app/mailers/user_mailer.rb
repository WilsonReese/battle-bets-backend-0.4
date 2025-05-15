class UserMailer < Devise::Mailer
  default from: 'no-reply@battlebets.app'

  # helper :application # allows you to use things like `root_url` if needed
  include Devise::Controllers::UrlHelpers # <– this gives you `confirmation_url`
  include Rails.application.routes.url_helpers # <– ensures route helpers work
  default template_path: 'user_mailer' # to use the devise views

  def confirmation_instructions(record, token, opts = {})
    @token = token
    @resource = record
    @confirmation_url = user_confirmation_url(confirmation_token: @token, host: 'localhost', port: 3000)

    mail(to: @resource.email, subject: "Confirm your Battle Bets account")
  end
end