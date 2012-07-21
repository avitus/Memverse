namespace :roster do
  desc "Start roster"
  task :start => :environment do
    puts "Emptying old roster items"
	Roster.destroy_all
	puts "Starting roster"
    Roster.subscribe
  end
end
