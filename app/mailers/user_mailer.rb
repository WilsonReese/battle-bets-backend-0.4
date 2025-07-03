class UserMailer < Devise::Mailer
  default from: ENV.fetch("MAILER_FROM", "no-reply@battlebets.app")

  include Devise::Controllers::UrlHelpers
  include Rails.application.routes.url_helpers

  default template_path: 'user_mailer'

  def confirmation_instructions(record, token, opts = {})
    @token = token
    @resource = record
    @confirmation_url = user_confirmation_url(confirmation_token: token)

    mail(to: @resource.email, subject: "Confirm your Battle Bets account")
  end
end