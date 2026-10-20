# Per-scenario coverage for CircleCI Smarter Testing test impact analysis, in the format the
# rspec-circleci-coverage gem writes for RSpec (there is no Cucumber plugin). A no-op unless
# CIRCLECI_COVERAGE is set. Required at the top of env.rb so code loaded at boot is tracked.
if ENV['CIRCLECI_COVERAGE'] && !defined?(CIRCLECI_COVERAGE_DATA)
  require 'coverage'
  require 'json'

  Coverage.start(lines: true, eval: true) unless Coverage.running?

  # { "app/models/user.rb" => { "features/users/sign_in.feature!!User signs in|run" => true } }
  CIRCLECI_COVERAGE_DATA = Hash.new { |hash, file| hash[file] = {} }

  module CircleCICoverage
    PROJECT_ROOT = "#{Dir.pwd}/".freeze

    def self.lines(coverage)
      coverage.is_a?(Hash) ? coverage[:lines] : coverage
    end

    # Project files with any line run more often than in the before snapshot
    def self.executed_files(before, after)
      after.filter_map do |file, coverage|
        next unless file.start_with?(PROJECT_ROOT) && !file.match?(%r{/(gems|vendor|\.bundle)/})

        after_lines = lines(coverage) or next
        before_lines = lines(before[file]) || []
        ran = after_lines.each_with_index.any? { |count, i| count && count > (before_lines[i] || 0) }
        file.delete_prefix(PROJECT_ROOT) if ran
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
    File.write(ENV['CIRCLECI_COVERAGE'], JSON.pretty_generate(CIRCLECI_COVERAGE_DATA))
  end
end
