namespace :roster do
  desc "Start roster"
  task :start => :environment do
    Roster.subscribe
    puts "Roster started"
  end
end
