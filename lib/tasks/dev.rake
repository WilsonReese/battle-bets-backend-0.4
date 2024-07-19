namespace :db do
  desc "Fill the database tables with some sample data"
  task sample_data: :environment do
    if Rails.env.development?
      Rails.logger.info "Deleting existing users..."
      puts "Deleting existing users..."
      User.delete_all
    end

    Rails.logger.info "Creating sample users..."
    puts "Creating sample users..."

    begin
      User.create!(
        email: "test@example.com",
        password: "password123",
        password_confirmation: "password123",
        username: "testuser",
        first_name: "Test",
        last_name: "User",
        avatar: "avatar_url"
      )
      Rails.logger.info "Sample users created successfully."
      puts "Sample users created successfully."
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Error creating sample users: #{e.message}"
    end
  end
end