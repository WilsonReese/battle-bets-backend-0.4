# lib/tasks/dev.rake
namespace :dev do
  desc "Fill the database tables with some sample data"
  task sample_data: :environment do
    if Rails.env.development?
      puts "Deleting bets, betslips, bet options, pool memberships, battles, games, users, and pools."
      Bet.delete_all
      Betslip.delete_all
      BetOption.delete_all
      PoolMembership.delete_all
      Battle.delete_all
      GameTeam.delete_all
      Team.delete_all
      Game.delete_all
      User.delete_all
      Pool.delete_all
    end

    puts "Creating sample users..."

    user1 = User.create!(
      id: 1,
      email: "user1@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "user1",
      first_name: "John",
      last_name: "Doe"
    )

    user2 = User.create!(
      id: 2,
      email: "user2@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "user2",
      first_name: "Jane",
      last_name: "Doe"
    )

    puts "Sample users created successfully."
    puts "Creating sample pools..."

    pool1 = Pool.create!(
      id: 1,
      name: "Pool 1"
    )

    pool2 = Pool.create!(
      id: 2,
      name: "Pool 2"
    )

    puts "Sample pools created successfully."
    puts "Creating sample pool memberships..."
    PoolMembership.create!(
      id: 1,
      user: user1,
      pool: pool1
    )

    PoolMembership.create!(
      id: 2,
      user: user2,
      pool: pool1
    )

    puts "Sample pool memberships created successfully."
    puts "Creating sample battles..."
    battle1 = Battle.create!(
      id: 1,
      start_date: DateTime.new(2024, 9, 8, 0, 0, 0),
      end_date: DateTime.new(2024, 9, 14, 23, 59, 59),
      pool: pool1
    )

    battle2 = Battle.create!(
      id: 2,
      start_date: DateTime.new(2024, 9, 15, 0, 0, 0),
      end_date: DateTime.new(2024, 9, 21, 23, 59, 59),
      pool: pool1
    )

    battle3 = Battle.create!(
      id: 3,
      start_date: DateTime.new(2024, 9, 15, 0, 0, 0),
      end_date: DateTime.new(2024, 9, 21, 23, 59, 59),
      pool: pool1
    )

    puts "Sample battles created successfully."
    puts "Creating sample betslips..."
    betslip1 = Betslip.create!(
      id: 1,
      user: user1,
      battle: battle1,
      name: 'User 1 Betslip'
    )

    betslip2 = Betslip.create!(
      id: 2,
      user: user2,
      battle: battle1,
      name: 'User 2 Betslip'
    )

    puts "Sample betslips created successfully."
    puts "Creating sample teams..."
    
    team_names = ["Vanderbilt", "Oklahoma", "Tennessee", "Texas", "Alabama", "Auburn", "Texas A&M", "LSU", "Ole Miss", "Mississippi St", "Missouri", "Arkansas", "Florida", "Georgia", "S Carolina", "Kentucky"]
    teams = team_names.map.with_index(1) do |name, index|
      Team.create!(id: index, name: name)
    end

    puts "Sample teams created successfully."
    puts "Creating sample games and game teams..."
    game1 = Game.create!(id: 1, start_time: "2024-09-15 15:00:00")
    GameTeam.create!(game: game1, team: teams[0], is_home: true)  # Vanderbilt
    GameTeam.create!(game: game1, team: teams[2], is_home: false) # Tennessee

    game2 = Game.create!(id: 2, start_time: "2024-09-15 18:00:00")
    GameTeam.create!(game: game2, team: teams[1], is_home: true)  # Oklahoma
    GameTeam.create!(game: game2, team: teams[3], is_home: false) # Texas

    game3 = Game.create!(id: 3, start_time: "2024-09-15 12:00:00")
    GameTeam.create!(game: game3, team: teams[4], is_home: true)  # Alabama
    GameTeam.create!(game: game3, team: teams[5], is_home: false) # Auburn

    game4 = Game.create!(id: 4, start_time: "2024-09-15 15:00:00")
    GameTeam.create!(game: game4, team: teams[6], is_home: true)  # Texas A&M
    GameTeam.create!(game: game4, team: teams[7], is_home: false) # LSU

    game5 = Game.create!(id: 5, start_time: "2024-09-15 15:00:00")
    GameTeam.create!(game: game5, team: teams[8], is_home: true)  # Ole Miss
    GameTeam.create!(game: game5, team: teams[9], is_home: false) # Mississippi St

    game6 = Game.create!(id: 6, start_time: "2024-09-15 18:00:00")
    GameTeam.create!(game: game6, team: teams[10], is_home: true) # Missouri
    GameTeam.create!(game: game6, team: teams[11], is_home: false) # Arkansas

    game7 = Game.create!(id: 7, start_time: "2024-09-15 12:00:00")
    GameTeam.create!(game: game7, team: teams[12], is_home: true) # Florida
    GameTeam.create!(game: game7, team: teams[13], is_home: false) # Georgia

    game8 = Game.create!(id: 8, start_time: "2024-09-15 15:00:00")
    GameTeam.create!(game: game8, team: teams[14], is_home: true) # S Carolina
    GameTeam.create!(game: game8, team: teams[15], is_home: false) # Kentucky

    puts "Sample games and game teams created successfully."
    puts "Creating sample bet options..."

    bet_option1 = BetOption.create!(
      id: 1,
      title: "Vanderbilt -6.5",
      payout: 2.0,
      category: "spread",
      game: game1
    )

    bet_option2 = BetOption.create!(
      id: 2,  
      title: "Tennessee + 6.5",
      payout: 2.0,
      category: "spread",
      game: game1
    )

    bet_option3 = BetOption.create!(
      id: 3,  
      title: "Over 45.5 Points",
      payout: 2.0,
      category: "ou",
      game: game1
    )

    bet_option4 = BetOption.create!(
      id: 4,
      title: "Under 45.5 Points",
      payout: 2.0,
      category: "ou",
      game: game1
    )

    puts "Sample bet options created successfully."
    puts "Creating sample bets..."

    Bet.create!(
      id: 1,
      betslip: betslip1,
      bet_option: bet_option1,
      bet_amount: 100,
    )

    Bet.create!(
      id: 2,
      betslip: betslip1,
      bet_option: bet_option3,
      bet_amount: 600,
    )

    Bet.create!(
      id: 3,
      betslip: betslip2,
      bet_option: bet_option2,
      bet_amount: 400,
    )

    Bet.create!(
      id: 4,
      betslip: betslip2,
      bet_option: bet_option3,
      bet_amount: 200,
    )

    puts "Sample bets created successfully."
  end
end
