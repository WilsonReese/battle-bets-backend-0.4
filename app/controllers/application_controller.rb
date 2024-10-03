class ApplicationController < ActionController::API
# Ensure devise is configured to work with APIs
    before_action :configure_permitted_parameters, if: :devise_controller?
    protected
    def configure_permitted_parameters
        devise_parameter_sanitizer.permit(:sign_up, keys: %i[username first_name last_name avatar])
        devise_parameter_sanitizer.permit(:account_update, keys: %i[username first_name last_name avatar])
    end

    private

  # Global authenticate_user! method
    def authenticate_user!
        token = request.headers['Authorization']&.split(' ')&.last
        Rails.logger.info "Token received: #{token}"

        if token.blank?
            Rails.logger.error "Token is missing!"
            render json: { error: 'Token is missing' }, status: :unauthorized
            return
        end

        begin
            decoded_token = JWT.decode(token, Rails.application.credentials.devise_jwt_secret_key!, true, algorithm: 'HS256')
            Rails.logger.info "Decoded token: #{decoded_token}" # Log the decoded token
            user_id = decoded_token[0]['sub']
            @current_user = User.find(user_id)
        rescue JWT::DecodeError => e
            Rails.logger.error "Invalid token! #{e.message}"
            render json: { error: 'Unauthorized' }, status: :unauthorized
        end
    end

    def current_user
        @current_user
    end
end
