# Row counts, max id and max updated_at for every table. `cutover.sh verify` runs it on both hosts and
# diffs the outputs; the only expected difference after the cutover restore is `sessions` (0 rows on the
# target). Data lines start with ROW (production boot also logs to stdout and those lines must not be
# compared); the trailer proves the run reached the end, so a crashed run cannot compare as equal.
# Plan §9 step 7 / Appendix A.3.
c = ActiveRecord::Base.connection
c.tables.sort.each do |t|
  cols = c.columns(t).map(&:name)
  n   = c.select_value("SELECT COUNT(*) FROM `#{t}`")
  mx  = cols.include?("id") ? c.select_value("SELECT MAX(id) FROM `#{t}`") : "-"
  upd = cols.include?("updated_at") ? c.select_value("SELECT MAX(updated_at) FROM `#{t}`") : "-"
  puts ["ROW", t, n, mx, upd].join("\t")
end
puts "ROW\tschema_migrations_total\t#{c.select_value('SELECT COUNT(*) FROM schema_migrations')}"
puts "COUNTS COMPLETE\t#{c.tables.size} tables"
