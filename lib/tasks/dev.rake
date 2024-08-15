# lib/tasks/dev.rake
namespace :dev do
  desc "Fill the database tables with some sample data"
  task sample_data: :environment do
    if Rails.env.development?
      puts "Deleting betslips, pool memberships, battles, users, and pools."
      Betslip.delete_all
      BetOption.delete_all
      PoolMembership.delete_all
      Battle.delete_all
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

    puts "Sample battles created successfully."

    puts "Creating sample betslips..."
    Betslip.create!(
      id: 1,
      user: user1,
      battle: battle1,
      name: 'User 1 Betslip'
    )

    Betslip.create!(
      id: 2,
      user: user2,
      battle: battle1,
      name: 'User 2 Betslip'
    )

    puts "Sample betslips created successfully."

    puts "Creating sample games..."

    game1 = Game.create!(
      id: 1,
      start_time: DateTime.new(2024, 9, 21, 11, 0, 0)
    )

    puts "Sample games created successfully."

    puts "Creating sample bet options..."

    BetOption.create!(
      id: 1,
      title: "Vanderbilt -6.5",
      payout: 2.0,
      category: "spread",
      game: game1
    )

    BetOption.create!(
      id: 2,  
      title: "Tennessee + 6.5",
      payout: 2.0,
      category: "spread",
      game: game1
    )

    BetOption.create!(
      id: 3,  
      title: "Over 45.5 Points",
      payout: 2.0,
      category: "ou",
      game: game1
    )

    BetOption.create!(
      id: 4,
      title: "Under 45.5 Points",
      payout: 2.0,
      category: "ou",
      game: game1
    )

    puts "Sample bet options created successfully."
  end
end
