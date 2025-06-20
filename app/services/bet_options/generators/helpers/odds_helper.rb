module BetOptions
  module Generators
    module Helpers
      module OddsHelper
        def implied_probability(american_odds)
          if american_odds > 0
            100.0 / (american_odds + 100.0)
          else
            american_odds.abs / (american_odds.abs + 100.0)
          end
        end

        def fair_decimal_odds(o1, o2)
          p1 = implied_probability(o1)
          p2 = implied_probability(o2)
          total = p1 + p2
          [(1.0/(p1/total)).round(1), (1.0/(p2/total)).round(1)]
        end
      end
    end
  end
end