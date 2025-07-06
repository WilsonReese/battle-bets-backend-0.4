class UserMailer < Devise::Mailer
  default from: ENV.fetch("MAILER_FROM", "no-reply@battlebets.app")

  include Devise::Controllers::UrlHelpers
  include Rails.application.routes.url_helpers

  default template_path: 'user_mailer'

  def confirmation_instructions(record, token, opts = {})
    @token = token
    @resource = record
    @confirmation_url = user_confirmation_url(confirmation_token: token)

    if Rails.env.production? || Rails.env.staging?
      # ✅ Use Postmark API in production/staging
      client = Postmark::ApiClient.new(ENV["POSTMARK_API_TOKEN"])
      Rails.logger.info "🔢 Postmark Template ID: #{ENV['POSTMARK_CONFIRMATION_TEMPLATE_ID']}"

      client.deliver_with_template(
        from: ENV.fetch("MAILER_FROM", "no-reply@battlebets.app"),
        to: @resource.email,
        template_id: ENV["POSTMARK_CONFIRMATION_TEMPLATE_ID"].to_i,
        template_model: {
          first_name: @resource.first_name || "there",
          confirmation_url: @confirmation_url
        }
      )
      # Return nil to skip ActionMailer
      return
    else
      # ✅ Use default Devise/ActionMailer flow in development
      super
    end
  end

  def reset_password_instructions(record, token, opts = {})
    @token = token
    @resource = record
    @reset_url = edit_user_password_url(reset_password_token: token)

    if Rails.env.production? || Rails.env.staging?
      client = Postmark::ApiClient.new(ENV["POSTMARK_API_TOKEN"])

      client.deliver_with_template(
        from: ENV.fetch("MAILER_FROM", "no-reply@battlebets.app"),
        to: @resource.email,
        template_id: ENV["POSTMARK_PASSWORD_RESET_TEMPLATE_ID"].to_i,
        template_model: {
          first_name: @resource.first_name || "there",
          reset_url: @reset_url
        }
      )

      return
    else
      super
    end
  end
end