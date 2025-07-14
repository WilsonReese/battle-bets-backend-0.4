module BettingRules
  RULES = {
    "spread"     => { min: 100, max: 1000 },
    "ou"         => { min: 100, max: 1000 },
    "money_line" => { min: 100, max: 500 },
    "prop"       => { min: 100, max: 500 }
  }.freeze

  DEFAULT_BUDGETS = {
    "spread_ou"   => 2_000,  # spread + ou combined
    "money_line"  => 1_000,
    "prop"        =>   500
  }.freeze

  CATEGORY_TO_BUDGET = {
    "spread"     => "spread_ou",
    "ou"         => "spread_ou",
    "money_line" => "money_line",
    "prop"       => "prop"
  }.freeze
end