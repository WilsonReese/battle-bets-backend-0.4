class UserMailer < Devise::Mailer
  default from: ENV.fetch("MAILER_FROM", "no-reply@battlebets.app")

  include Devise::Controllers::UrlHelpers
  include Rails.application.routes.url_helpers

  default template_path: 'user_mailer'

  def confirmation_instructions(record, token, opts = {})
    @token = token
    @resource = record
    @confirmation_url = user_confirmation_url(confirmation_token: token)

    mail(
      to: @resource.email,
      template_id: ENV["POSTMARK_CONFIRMATION_TEMPLATE_ID"], # ⬅️ Template ID from Postmark
      message_stream: "outbound",
      template_model: {
        resource: {
          first_name: @resource.first_name || "there"
        },
        confirmation_url: confirmation_url
      }
    )
  end
end