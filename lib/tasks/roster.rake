namespace :roster do
  desc "Starting roster"
  task :start => :environment do
    Roster.subscribe
  end
end
