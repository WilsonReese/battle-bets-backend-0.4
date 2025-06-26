SEASON_SCORING_RULES = [
  {
    range: 0..7,
    tiers: [
      { top: 1,  points: 50 },
      { top: 2,  points: 35 },
      { top: 3,  points: 25 }
    ]
  },
  {
    range: 8..11,
    tiers: [
      { top: 1,        points: 50 },
      { top: 2,        points: 35 },
      { top: 3,        points: 25 },
      { top_pct: 0.50, points: 10 }
    ]
  },
  {
    range: 12..17,
    tiers: [
      { top: 1,        points: 50 },
      { top: 2,        points: 35 },
      { top_pct: 0.25, points: 25 },
      { top_pct: 0.50, points: 10 }
    ]
  },
  {
    range: 18..25,
    tiers: [
      { top: 1,        points: 50 },
      { top: 3,        points: 35 },
      { top: 5,        points: 25 },
      { top_pct: 0.50, points: 10 }
    ]
  },
  {
    range: 26..39,
    tiers: [
      { top: 1,        points: 50 },
      { top: 3,        points: 35 },
      { top_pct: 0.25, points: 25 },
      { top_pct: 0.50, points: 10 }
    ]
  },
  {
    range: 40..Float::INFINITY,
    tiers: [
      { top: 1,        points: 50 },
      { top_pct: 0.10, points: 35 },
      { top_pct: 0.25, points: 25 },
      { top_pct: 0.50, points: 10 }
    ]
  }
].freeze