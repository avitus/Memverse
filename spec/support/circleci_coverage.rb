# Completes the rspec-circleci-coverage file (the gem is required at the top of spec_helper) for
# CircleCI Smarter Testing test impact analysis. Files whose lines all ran while loading, such as a
# model of only associations and validations under CI's eager loading, map to no example. Map them
# to every example instead, so changing one runs the whole suite rather than nothing. Runs at exit,
# after the gem has written the file; features/support/circleci_coverage.rb does the same for Cucumber.
if ENV['CIRCLECI_COVERAGE']
  at_exit do
    coverage_file = ENV['CIRCLECI_COVERAGE']
    next unless File.exist?(coverage_file)

    data = JSON.parse(File.read(coverage_file))
    every_example = data.values.flat_map(&:keys).uniq.to_h { |key| [key, true] }
    project_root = "#{Dir.pwd}/"
    Coverage.peek_result.each_key do |file|
      next unless file.start_with?(project_root) && !file.match?(%r{/(gems|vendor|\.bundle)/}) && !file.end_with?('_spec.rb')

      data[file.delete_prefix(project_root)] ||= every_example
    end

    File.write(coverage_file, JSON.pretty_generate(data))
  end
end
