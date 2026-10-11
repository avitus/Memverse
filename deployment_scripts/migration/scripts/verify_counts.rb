# Row counts, max id and max updated_at for every table. Run on both hosts and diff the outputs:
#   RAILS_ENV=production bundle exec rails runner deployment_scripts/migration/scripts/verify_counts.rb > counts_$(hostname).txt
# Expected differences after the cutover restore: `sessions` only (0 rows on the target).
# Plan §9 step 7 / Appendix A.3.
c = ActiveRecord::Base.connection
c.tables.sort.each do |t|
  cols = c.columns(t).map(&:name)
  n   = c.select_value("SELECT COUNT(*) FROM `#{t}`")
  mx  = cols.include?("id") ? c.select_value("SELECT MAX(id) FROM `#{t}`") : "-"
  upd = cols.include?("updated_at") ? c.select_value("SELECT MAX(updated_at) FROM `#{t}`") : "-"
  puts [t, n, mx, upd].join("\t")
end
puts "schema_migrations\t#{c.select_value('SELECT COUNT(*) FROM schema_migrations')}"
