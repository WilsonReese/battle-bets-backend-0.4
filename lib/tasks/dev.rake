# lib/tasks/dev.rake
namespace :dev do
  desc "Fill the database tables with some sample data"
  task sample_data: :environment do

    # Test for commit

    if Rails.env.development? || Rails.env.production? || Rails.env.staging?
      puts "Deleting bets, betslips, bet options, pool memberships, battles, games, users, and pools."
      Bet.delete_all
      Betslip.delete_all
      BetOption.delete_all
      PoolMembership.delete_all
      Battle.delete_all
      Game.delete_all
      # Team.delete_all
      LeaderboardEntry.delete_all
      User.delete_all
      LeagueSeason.delete_all
      Season.delete_all
      Pool.delete_all
    end

    puts "Creating sample users..."

    user1 = User.create!(
      # id: 1,
      email: "reese@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "reese",
      first_name: "Reese",
      last_name: "Wilson", 
      confirmed_at: Time.now
    )

    user2 = User.create!(
      # id: 2,
      email: "logan@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "logan",
      first_name: "Logan",
      last_name: "Dunn",
      confirmed_at: Time.now
    )
    user3 = User.create!(
      # id: 3,
      email: "ben@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "ben",
      first_name: "Ben",
      last_name: "Parker",
      confirmed_at: Time.now
    )
    user4 = User.create!(
      # id: 4,
      email: "chandler@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "chandler",
      first_name: "Chandler",
      last_name: "Hawkins",
      confirmed_at: Time.now
    )

    user5 = User.create!(
      # id: 4,
      email: "chandler2@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "chandler2",
      first_name: "Chandler",
      last_name: "Hawkins",
      confirmed_at: Time.now
    )

    user6 = User.create!(
      # id: 4,
      email: "chandler6@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "chandler6",
      first_name: "Chandler",
      last_name: "Hawkins",
      confirmed_at: Time.now
    )

    user7 = User.create!(
      # id: 4,
      email: "chandler7@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "chandler7",
      first_name: "Chandler",
      last_name: "Hawkins",
      confirmed_at: Time.now
    )

    user8 = User.create!(
      # id: 4,
      email: "chandler8@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "chandler8",
      first_name: "Chandler",
      last_name: "Hawkins",
      confirmed_at: Time.now
    )

    user9 = User.create!(
      # id: 4,
      email: "chandler9@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "chandler9",
      first_name: "Chandler",
      last_name: "Hawkins",
      confirmed_at: Time.now
    )

    user10 = User.create!(
      # id: 4,
      email: "chandler10@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "chandler10",
      first_name: "Chandler",
      last_name: "Hawkins",
      confirmed_at: Time.now
    )

    user11 = User.create!(
      # id: 4,
      email: "chandler11@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "chandler11",
      first_name: "Chandler",
      last_name: "Hawkins",
      confirmed_at: Time.now
    )

    user12 = User.create!(
      # id: 4,
      email: "chandler12@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "chandler12mmmmmmmmmm",
      first_name: "Chandler",
      last_name: "Hawkins",
      confirmed_at: Time.now
    )

    puts "Sample users created successfully."
    puts "Creating sample pools..."

    pool1 = Pool.create!(
      # id: 1,
      name: "Pool 1"
    )

    pool2 = Pool.create!(
      # id: 2,
      name: "Pool 2"
    )

    puts "Sample pools created successfully."
    puts "Creating sample pool memberships..."
    PoolMembership.create!(
      # id: 1,
      user: user1,
      pool: pool1,
      is_commissioner: true,
      created_at: 2.years.ago
    )

    PoolMembership.create!(
      # id: 2,
      user: user2,
      pool: pool1,
      created_at: 100.days.ago
    )

    PoolMembership.create!(
      # id: 3,
      user: user1,
      pool: pool2,
      is_commissioner: true
    )

    PoolMembership.create!(
      # id: 5,
      user: user4,
      pool: pool1,
      created_at: 3.hours.ago
    )
    PoolMembership.create!(
      # id: 4,
      user: user3,
      pool: pool1
    )

    PoolMembership.create!(
      # id: 4,
      user: user3,
      pool: pool2
    )

    PoolMembership.create!(
      # id: 4,
      user: user5,
      pool: pool1
    )

    PoolMembership.create!(
      # id: 4,
      user: user6,
      pool: pool1
    )

    PoolMembership.create!(
      # id: 4,
      user: user7,
      pool: pool1
    )

    PoolMembership.create!(
      # id: 4,
      user: user8,
      pool: pool1
    )

    PoolMembership.create!(
      # id: 4,
      user: user9,
      pool: pool1
    )

    PoolMembership.create!(
      # id: 4,
      user: user10,
      pool: pool1
    )

    PoolMembership.create!(
      # id: 4,
      user: user11,
      pool: pool1
    )

    PoolMembership.create!(
      # id: 4,
      user: user12,
      pool: pool1
    )


    puts "Sample pool memberships created successfully."

    puts "Creating sample Seasons..."
    season2023 = Season.create!(
      # id: 1,
      start_date: DateTime.new(2023, 8, 1, 0, 0, 0),
      end_date: DateTime.new(2024, 2, 1, 0, 0, 0),
      year: 2023
    )
    
    season2024 = Season.create!(
      # id: 1,
      start_date: DateTime.new(2024, 8, 1, 0, 0, 0),
      end_date: DateTime.new(2025, 2, 1, 0, 0, 0),
      year: 2024
    )

    season2025 = Season.create!(
      start_date: DateTime.new(2025, 8, 1, 0, 0, 0),
      end_date: DateTime.new(2026, 2, 1, 0, 0, 0),
      year: 2025
    )

    puts "Sample Seasons created successfully."

    puts "Creating sample League Seasons..."
    league_season1 = LeagueSeason.create!(
      # id: 1,
      pool: pool1,
      season: season2025, 
      start_week: 1
    )

    league_season2 = LeagueSeason.create!(
      # id: 2,
      pool: pool2,
      season: season2025,
      start_week: 1
    )

    puts "Sample League Seasons created successfully."

    puts "Updating sample Leaderboard Entries with points..."
    LeaderboardEntry.find_or_initialize_by(
      league_season: league_season1,
      user: user1
    ).tap do |entry|
      entry.total_points = 90
      entry.save!
    end
    
    LeaderboardEntry.find_or_initialize_by(
      league_season: league_season2,
      user: user1
    ).tap do |entry|
      entry.total_points = 50
      entry.save!
    end

    LeaderboardEntry.find_or_initialize_by(
      league_season: league_season1,
      user: user2
    ).tap do |entry|
      entry.total_points = 90
      entry.save!
    end
    
    LeaderboardEntry.find_or_initialize_by(
      league_season: league_season2,
      user: user3
    ).tap do |entry|
      entry.total_points = 20
      entry.save!
    end


    puts "Updated Leaderboard Entries successfully."
  end

  desc "Create 100 users, 6 demo pools, pool memberships, and league seasons"
  task expanded_sample_data: :environment do
    # puts "🧹  Clearing old sample data…"
    # PoolMembership.delete_all
    # LeagueSeason.delete_all
    # Pool.delete_all
    # User.where.not(username: 'reese').delete_all  # keep the real Reese if already present

    puts "👥  Seeding users…"
    users = []

    # Ensure the 'reese' account exists
    users << User.find_or_create_by!(username: "reese") do |u|
      u.email                 = "reese@example.com"
      u.first_name            = "Reese"
      u.last_name             = "Wilson"
      u.password              = "password123"
      u.password_confirmation = "password123"
      u.confirmed_at          = Time.current
    end

    # Create 99 more fake users
    99.times do
      username = nil

      loop do
        username_candidate = Faker::Internet.unique.username(specifier: 5..12).gsub(/[^a-zA-Z0-9_]/, '_')
        if username_candidate =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/
          username = username_candidate
          break
        end
      end

      users << User.create!(
        email:                 Faker::Internet.unique.email,
        username:              username,
        first_name:            Faker::Name.first_name,
        last_name:             Faker::Name.last_name,
        password:              "password123",
        password_confirmation: "password123",
        confirmed_at:          Time.current
      )
    end

    puts "🏆  Creating demo pools…"
    pool_specs = [
      { name: "6 Man League",  size: 6  },
      { name: "10 Man League", size: 10 },
      { name: "15 Man League", size: 15 },
      { name: "22 Man League", size: 22 },
      { name: "35 Man League", size: 35 },
      { name: "100 Man League",size: 100 }
    ]

    pool_specs.each do |spec|
      pool = Pool.create!(name: spec[:name])

      # --- memberships ---------------------------------------------------
      # Always include Reese
      members = [users.first] + users.sample(spec[:size] - 1)

      members.each_with_index do |user, i|
        PoolMembership.find_or_create_by!(user: user, pool: pool) do |membership|
          membership.is_commissioner = i < 2 # Reese + 1 other commissioner
        end
      end

      # --- league season --------------------------------------------------
      season_2025 = Season.find_or_create_by!(year: 2025)
      LeagueSeason.create!(
        pool:       pool,
        season:     season_2025,
        start_week: 1
      )

      puts "  → #{spec[:name]} seeded with #{spec[:size]} members"
    end

    puts "✅  Sample data generated!"
  end

  desc "Reset sample data: clear bets, betslips, options, battles; reset leaderboard and season state"
  task reset_sample_data: :environment do
    puts "🧹 Resetting sample data…"

    puts "🗑️  Deleting bets, betslips, bet options, and battles…"
    Bet.delete_all
    Betslip.delete_all
    BetOption.delete_all
    Battle.delete_all

    puts "🔄 Resetting leaderboard entries…"
    # LeaderboardEntry.update_all(total_points: 0, ranking: nil)
    LeagueSeason.includes(:leaderboard_entries).find_each do |league_season|
      entries = league_season.leaderboard_entries

      # Reset scores and rankings first
      entries.find_each do |entry|
        entry.update_columns(total_points: 0, ranking: nil) # no callbacks needed here
      end

      # Recalculate rankings (will set all to rank 1 since all have 0)
      if entries.any?
        entries.first.update_rankings # triggers ranking update for whole season
      end
    end

    puts "🔄 Unlocking all games…"
    Game.update_all(battles_locked: false)

    puts "🔄 Resetting current_week on all seasons…"
    Season.update_all(current_week: 0)

    puts "✅ Sample data has been reset."
  end

  desc "Populate each betslip with a single random bet"
  task sample_bets: :environment do
    amount_choices = [100, 200, 300, 400, 500]

    total_created = 0
    total_skipped = 0

    puts "🎲  Creating sample bets…"

    Betslip.find_each do |betslip|
      attempts = 0
      created  = false

      while attempts < 5 && !created
        bet_option = BetOption.order(Arel.sql('RANDOM()')).first
        attempts  += 1

        begin
          Bet.create!(
            betslip:      betslip,
            bet_option:   bet_option,
            bet_amount:   amount_choices.sample
          )
          total_created += 1
          created = true
        rescue ActiveRecord::RecordInvalid => e
          # most likely uniqueness validation on (betslip_id, bet_option_id)
          puts "❌ Skipped betslip ##{betslip.id}: #{e.record.errors.full_messages.join(', ')}"

          total_skipped += 1 if attempts == 5
        end
      end
    end

    puts "✅  #{total_created} bets created, #{total_skipped} skipped."
  end
end
