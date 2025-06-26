class SeasonScoringService
  def self.points_for(rank, size)
    rule = SEASON_SCORING_RULES.find { |r| r[:range].cover?(size) }
    raise "No scoring rule for size #{size}" unless rule

    rule[:tiers].each do |tier|
      return tier[:points] if tier[:top] && rank <= tier[:top]
      return tier[:points] if tier[:top_pct] && rank <= (size * tier[:top_pct]).ceil
    end

    0
  end
end