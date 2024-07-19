class ApplicationController < ActionController::API
# Ensure devise is configured to work with APIs
    before_action :configure_permitted_parameters, if: :devise_controller?
    protected
    def configure_permitted_parameters
        devise_parameter_sanitizer.permit(:sign_up, keys: %i[username first_name last_name avatar])
        devise_parameter_sanitizer.permit(:account_update, keys: %i[username first_name last_name avatar])
    end
end
