
require "devise/jwt/revocation_strategies/jti_matcher"

module Devise
  module JWT
    module RevocationStrategies
      class JTIMatcher
        class << self
          # wrap the original revoke_jwt
          alias_method :orig_revoke_jwt, :revoke_jwt

          def revoke_jwt(payload, user)
            # if the user record is nil, just skip revocation
            return unless user
            orig_revoke_jwt(payload, user)
          end
        end
      end
    end
  end
end