# Per-scenario coverage for CircleCI Smarter Testing test impact analysis, in the format the
# rspec-circleci-coverage gem writes for RSpec (there is no Cucumber plugin). A no-op unless
# CIRCLECI_COVERAGE is set. Required at the top of env.rb so code loaded at boot is tracked.
if ENV['CIRCLECI_COVERAGE'] && !defined?(CIRCLECI_COVERAGE_DATA)
  require 'coverage'
  require 'json'

  Coverage.start(lines: true, eval: true) unless Coverage.running?

  # { "app/models/user.rb" => { "features/users/sign_in.feature!!User signs in|run" => true } }
  CIRCLECI_COVERAGE_DATA = Hash.new { |hash, file| hash[file] = {} }

  # Reads Ruby's Coverage results for the hooks below
  module CircleCICoverage
    PROJECT_ROOT = "#{Dir.pwd}/".freeze

    # Path relative to the project, or nil for gems and files outside it
    def self.project_path(file)
      file.delete_prefix(PROJECT_ROOT) if file.start_with?(PROJECT_ROOT) && !file.match?(%r{/(gems|vendor|\.bundle)/})
    end

    # Per-line run counts from a Coverage result entry (a Hash when started with lines: true)
    def self.lines(coverage)
      coverage.is_a?(Hash) ? coverage[:lines] : coverage
    end

    # Project files with any line run more often than in the before snapshot
    def self.executed_files(before, after)
      after.filter_map do |file, coverage|
        path = project_path(file) or next
        after_lines = lines(coverage) or next
        before_lines = lines(before[file]) || []
        path if after_lines.each_with_index.any? { |count, i| count && count > (before_lines[i] || 0) }
      end
    end
  end

  Before do
    @circleci_coverage_before = Coverage.peek_result
  end

  After do |scenario|
    feature_file = scenario.location.file
    test_key = "#{feature_file}!!#{scenario.name}|run"
    # The feature file is not Ruby, so record it explicitly: editing a scenario selects it
    CIRCLECI_COVERAGE_DATA[feature_file][test_key] = true
    CircleCICoverage.executed_files(@circleci_coverage_before, Coverage.peek_result).each do |file|
      CIRCLECI_COVERAGE_DATA[file][test_key] = true
    end
  end

  AfterAll do
    # Files whose lines all ran while loading, such as a model of only associations and validations
    # under CI's eager loading, map to no scenario. Map them to every scenario instead, so changing
    # one runs the whole suite rather than nothing.
    every_scenario = CIRCLECI_COVERAGE_DATA.values.flat_map(&:keys).uniq.index_with(true)
    Coverage.peek_result.each_key do |file|
      path = CircleCICoverage.project_path(file)
      CIRCLECI_COVERAGE_DATA[path] = every_scenario if path && !CIRCLECI_COVERAGE_DATA.key?(path)
    end

    File.write(ENV['CIRCLECI_COVERAGE'], JSON.pretty_generate(CIRCLECI_COVERAGE_DATA))
  end
end
