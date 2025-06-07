# lib/tasks/dev.rake
namespace :dev do
  desc "Fill the database tables with some sample data"
  task sample_data: :environment do
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
      username: "reesemmmmmmmmmmmmmmm",
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
    season2024 = Season.create!(
      # id: 1,
      start_date: DateTime.new(2024, 8, 1, 0, 0, 0),
      end_date: DateTime.new(2025, 2, 1, 0, 0, 0),
      year: 2024
    )

    puts "Sample Seasons created successfully."

    puts "Creating sample League Seasons..."
    league_season1 = LeagueSeason.create!(
      # id: 1,
      pool: pool1,
      season: season2024, 
      start_week: 1
    )

    league_season2 = LeagueSeason.create!(
      # id: 2,
      pool: pool2,
      season: season2024,
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
    

    puts "Creating sample battles..."

    # Will need to re-create this to be associated with a league season
    # battle1 = Battle.create!(
    #   # id: 1,
    #   start_date: DateTime.new(2024, 9, 8, 0, 0, 0),
    #   end_date: DateTime.new(2024, 9, 14, 23, 59, 59),
    #   league_season: league_season1,
    #   locked: true,
    #   week: 1,
    #   status: 2,
    # )
    # Battle.find_by!(league_season: league_season1, week: 1).update!(locked: true, status: 2)


    # battle2 = Battle.create!(
    #   # id: 2,
    #   start_date: DateTime.new(2024, 9, 15, 0, 0, 0),
    #   end_date: DateTime.new(2024, 9, 21, 23, 59, 59),
    #   league_season: league_season1,
    #   locked: true,
    #   week: 2,
    #   status: 2,
    # )

    # battle3 = Battle.create!(
    #   # id: 3,
    #   start_date: DateTime.new(2024, 9, 22, 0, 0, 0),
    #   end_date: DateTime.new(2024, 9, 28, 23, 59, 59),
    #   league_season: league_season1,
    #   locked: true,
    #   week: 3,
    #   status: 2,
    # )

    # battle4 = Battle.create!(
    #   # id: 4,
    #   start_date: DateTime.new(2025, 12, 1, 0, 0, 0),
    #   end_date: DateTime.new(2025, 12, 7, 23, 59, 59),
    #   league_season: league_season1, 
    #   week: 10,
    #   status: 0,
    #   current: false,
    # )

    # battle5 = Battle.create!(
    #   # id: 5,
    #   start_date: DateTime.new(2025, 12, 1, 0, 0, 0),
    #   end_date: DateTime.new(2025, 12, 7, 23, 59, 59),
    #   league_season: league_season2,
    #   week: 10,
    #   status: 0,
    #   current: false,
    # )

    # battle6 = Battle.create!(
    #   # id: 5,
    #   start_date: DateTime.new(2025, 12, 8, 0, 0, 0),
    #   end_date: DateTime.new(2025, 12, 14, 23, 59, 59),
    #   league_season: league_season1,
    #   week: 11,
    #   status: 0,
    # )

    # battle7 = Battle.create!(
    #   # id: 5,
    #   start_date: DateTime.new(2025, 12, 8, 0, 0, 0),
    #   end_date: DateTime.new(2025, 12, 14, 23, 59, 59),
    #   league_season: league_season2,
    #   week: 11,
    #   status: 0,
    # )

    puts "Sample battles created successfully."
    puts "Skipping sample betslips..."
    # betslip1 = Betslip.create!(
    #   id: 1,
    #   user: user1,
    #   battle: battle1,
    #   name: 'User 1 Betslip'
    # )

    # betslip2 = Betslip.create!(
    #   id: 2,
    #   user: user2,
    #   battle: battle1,
    #   name: 'User 2 Betslip'
    # )

    puts "Skipped betslips successfully."
    puts "Skip creating teams:"
    
    # team_names = ["Vanderbilt", "Oklahoma", "Tennessee", "Texas", "Alabama", "Auburn", "Texas A&M", "LSU", "Ole Miss", "Mississippi St", "Missouri", "Arkansas", "Florida", "Georgia", "S Carolina", "Kentucky", "Penn St", "Oregon", "Iowa St", "Arizona St", "SMU", "Clemson"]
    # teams = team_names.map.with_index(1) do |name, index|
    #   Team.create!(id: index, name: name)
    # end

    puts "Sample teams skipped successfully."
    puts "Creating sample games..."

    games = [
      { id: 1, start_time: "2025-12-07 15:00:00", away_team: "Georgia", home_team: "Texas" },
      { id: 2, start_time: "2025-12-07 19:00:00", away_team: "Penn State", home_team: "Oregon" },
      { id: 3, start_time: "2025-12-07 11:00:00", away_team: "Iowa State", home_team: "Arizona St" },
      { id: 4, start_time: "2025-12-07 19:00:00", away_team: "Clemson", home_team: "SMU" },
      { id: 5, start_time: "2025-12-07 19:00:00", away_team: "Tennessee", home_team: "Vanderbilt" },
      { id: 6, start_time: "2025-12-07 19:00:00", away_team: "Mississippi St", home_team: "South Carolina" }
    ]

    games.each do |g|
      away = Team.find_by!(name: g[:away_team])
      home = Team.find_by!(name: g[:home_team])

      Game.create!(
        id: g[:id],
        start_time: g[:start_time],
        away_team: away,
        home_team: home
      )
    end 


    puts "Sample games created successfully."
    puts "Skip creating sample bet options..."

    # bet_option1 = BetOption.create!(
    #   id: 1,
    #   title: "Vanderbilt -6.5",
    #   payout: 2.0,
    #   category: "spread",
    #   game: game1
    # )

    # bet_option2 = BetOption.create!(
    #   id: 2,  
    #   title: "Tennessee + 6.5",
    #   payout: 2.0,
    #   category: "spread",
    #   game: game1
    # )

    # bet_option3 = BetOption.create!(
    #   id: 3,  
    #   title: "Over 45.5 Points",
    #   payout: 2.0,
    #   category: "ou",
    #   game: game1
    # )

    # bet_option4 = BetOption.create!(
    #   id: 4,
    #   title: "Under 45.5 Points",
    #   payout: 2.0,
    #   category: "ou",
    #   game: game1
    # )

    puts "Sample bet options skipped successfully."
    puts "Skipping sample bets..."

    # Bet.create!(
    #   id: 1,
    #   betslip: betslip1,
    #   # bet_option: BetOption.first,
    #   bet_amount: 100,
    # )

    # Bet.create!(
    #   id: 2,
    #   betslip: betslip1,
    #   bet_option: bet_option3,
    #   bet_amount: 600,
    # )

    # Bet.create!(
    #   id: 3,
    #   betslip: betslip2,
    #   bet_option: bet_option2,
    #   bet_amount: 400,
    # )

    # Bet.create!(
    #   id: 4,
    #   betslip: betslip2,
    #   bet_option: bet_option3,
    #   bet_amount: 200,
    # )

    puts "Sample bets skipped successfully."
  end
end
