# frozen_string_literal: true

module Ahoy
  # One analytics event (ahoy_events): a page view ("$view") or a product event
  # such as signed_up, verse_added, verse_rated or reference_tested, with JSON
  # properties. See documentation/ANALYTICS.md.
  class Event < ApplicationRecord
    include Ahoy::QueryMethods

    self.table_name = "ahoy_events"

    belongs_to :visit
    belongs_to :user, optional: true
  end
end
