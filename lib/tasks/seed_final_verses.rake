namespace :db do
  namespace :seed_final_verses do 
    desc "load the seed data from iso_final_verses.sql into the test database"
    task :load => :environment do
      config = ActiveRecord::Base.configurations['test']
      # system("mysql --user=#{config['username']} --password=#{config['password']} #{config['database']} < db/#{RAILS_ENV}_seed.sql")      
      system("sqlite3 #{config['database']} < iso_final_verses.sql")
      
     end
  end
end