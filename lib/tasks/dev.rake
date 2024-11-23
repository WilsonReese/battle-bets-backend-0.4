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
      Game.delete_all
      Team.delete_all
      User.delete_all
      Pool.delete_all
    end

    puts "Creating sample users..."

    user1 = User.create!(
      id: 3,
      email: "user3@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "user3",
      first_name: "John",
      last_name: "Doe"
    )

    user2 = User.create!(
      id: 4,
      email: "user4@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "user4",
      first_name: "Jane",
      last_name: "Doe"
    )

    puts "Sample users created successfully."
    puts "Creating sample pools..."

    pool3 = Pool.create!(
      id: 3,
      name: "Pool 3"
    )

    pool4 = Pool.create!(
      id: 4,
      name: "Pool 4"
    )

    puts "Sample pools created successfully."
    puts "Creating sample pool memberships..."
    PoolMembership.create!(
      id: 4,
      user: user3,
      pool: pool3
    )

    PoolMembership.create!(
      id: 5,
      user: user4,
      pool: pool3
    )

    PoolMembership.create!(
      id: 6,
      user: user3,
      pool: pool4
    )

    puts "Sample pool memberships created successfully."
    puts "Creating sample battles..."
    battle6 = Battle.create!(
      id: 6,
      start_date: DateTime.new(2024, 9, 8, 0, 0, 0),
      end_date: DateTime.new(2024, 9, 14, 23, 59, 59),
      pool: pool1
    )

    battle7 = Battle.create!(
      id: 7,
      start_date: DateTime.new(2024, 9, 15, 0, 0, 0),
      end_date: DateTime.new(2024, 9, 21, 23, 59, 59),
      pool: pool1
    )

    battle8 = Battle.create!(
      id: 8,
      start_date: DateTime.new(2024, 9, 15, 0, 0, 0),
      end_date: DateTime.new(2024, 9, 21, 23, 59, 59),
      pool: pool1
    )

    battle9 = Battle.create!(
      id: 9,
      start_date: DateTime.new(2024, 11, 17, 0, 0, 0),
      end_date: DateTime.new(2024, 11, 23, 23, 59, 59),
      pool: pool1
    )

    battle10 = Battle.create!(
      id: 10,
      start_date: DateTime.new(2024, 11, 17, 0, 0, 0),
      end_date: DateTime.new(2024, 11, 23, 23, 59, 59),
      pool: pool2
    )

    puts "Sample battles created successfully."
    puts "Creating sample betslips..."
    betslip3 = Betslip.create!(
      id: 3,
      user: user3,
      battle: battle6,
      name: 'User 1 Betslip'
    )

    betslip4 = Betslip.create!(
      id: 4,
      user: user4,
      battle: battle6,
      name: 'User 2 Betslip'
    )

    puts "Sample betslips created successfully."
    puts "Creating sample teams..."
    
    team_names = ["Vanderbilt", "Oklahoma", "Tennessee", "Texas", "Alabama", "Auburn", "Texas A&M", "LSU", "Ole Miss", "Mississippi St", "Missouri", "Arkansas", "Florida", "Georgia", "S Carolina", "Kentucky", "Ball St"]
    teams = team_names.map.with_index(1) do |name, index|
      Team.create!(id: index, name: name)
    end

    puts "Sample teams created successfully."
    puts "Skip creating sample games..."
    # game1 = Game.create!(
    #   id: 1,
    #   start_time: "2024-09-15 15:00:00",
    #   home_team_id: teams[0].id, # Vanderbilt
    #   away_team_id: teams[2].id  # Tennessee
    # )

    # game2 = Game.create!(
    #   id: 2,
    #   start_time: "2024-09-15 18:00:00",
    #   home_team_id: teams[1].id, # Oklahoma
    #   away_team_id: teams[3].id  # Texas
    # )

    # game3 = Game.create!(
    #   id: 3,
    #   start_time: "2024-09-15 12:00:00",
    #   home_team_id: teams[4].id, # Alabama
    #   away_team_id: teams[5].id  # Auburn
    # )

    # game4 = Game.create!(
    #   id: 4,
    #   start_time: "2024-09-15 15:00:00",
    #   home_team_id: teams[6].id, # Texas A&M
    #   away_team_id: teams[7].id  # LSU
    # )

    # game5 = Game.create!(
    #   id: 5,
    #   start_time: "2024-09-15 15:00:00",
    #   home_team_id: teams[8].id, # Ole Miss
    #   away_team_id: teams[9].id  # Mississippi St
    # )

    # game6 = Game.create!(
    #   id: 6,
    #   start_time: "2024-09-15 18:00:00",
    #   home_team_id: teams[10].id, # Missouri
    #   away_team_id: teams[11].id  # Arkansas
    # )

    # game7 = Game.create!(
    #   id: 7,
    #   start_time: "2024-09-15 12:00:00",
    #   home_team_id: teams[12].id, # Florida
    #   away_team_id: teams[13].id  # Georgia
    # )

    # game8 = Game.create!(
    #   id: 8,
    #   start_time: "2024-09-15 15:00:00",
    #   home_team_id: teams[14].id, # S Carolina
    #   away_team_id: teams[15].id  # Kentucky
    # )

    puts "Sample games skipped successfully."
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
