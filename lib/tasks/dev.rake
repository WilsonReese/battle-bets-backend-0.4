# lib/tasks/dev.rake
namespace :dev do
  desc "Fill the database tables with some sample data"
  task sample_data: :environment do
    if Rails.env.development?
      PoolMembership.delete_all
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
  end
end
