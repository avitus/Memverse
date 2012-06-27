namespace :roster do
  desc "Start roster"
  task :start => :environment do
    puts "Starting roster"
    Roster.subscribe
  end
end
