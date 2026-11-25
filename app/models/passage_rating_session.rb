# Same-day edits live in the existing SQL session table, in a separate keyspace
# from login sessions. Save the receipt and the SM-2 schedule in one transaction.
class PassageRatingSession < ApplicationRecord
  self.table_name = 'sessions'
  class StaleRating < StandardError; end

  def self.for_passage(passage)
    find_or_initialize_by(session_id: "passage-review:#{passage.user_id}:#{passage.id}")
  end

  def state_for(mv)
    saved = entries[mv.id.to_s]
    if saved && saved['baseline']['attempts'] + 1 == mv.attempts
      { day: Date.today.iso8601, attempt: saved['baseline']['attempts'], quality: saved['quality'] }
    else
      { day: Date.today.iso8601, attempt: mv.attempts, quality: nil }
    end
  end

  # Caller holds the passage and memverse locks. Corrections start from the
  # original inputs, so the scheduled result is the same as rating once.
  def rate!(mv, quality, day:, attempt:, previous:)
    state = state_for(mv)
    raise StaleRating unless state[:day] == day && state[:attempt] == attempt
    return :unchanged if state[:quality] == quality
    raise StaleRating unless state[:quality] == previous

    key = mv.id.to_s
    baseline = previous ? entries.fetch(key).fetch('baseline') : mv.attributes.slice(
      'rep_n', 'efactor', 'test_interval', 'next_test', 'status', 'attempts'
    )
    mv.assign_attributes(baseline) if previous
    memorized = mv.supermemo(quality)
    entries[key] = { 'quality' => quality, 'baseline' => baseline }
    update!(data: JSON.generate(day: day, ratings: entries))
    return :corrected if previous
    memorized ? :memorized : :rated
  end

  private

  def entries
    @entries ||= begin
      receipt = data.present? ? JSON.parse(data) : {}
      receipt['day'] == Date.today.iso8601 ? receipt.fetch('ratings') : {}
    end
  end
end
