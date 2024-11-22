namespace :db do
  desc "Seed the staging database with sample data"
  task seed_staging: :environment do
    if Rails.env.staging?
      puts "Seeding the staging database..."
      Rake::Task["dev:sample_data"].invoke
      puts "Staging database seeded successfully!"
    else
      puts "This task can only be run in the staging environment."
    end
  end
end