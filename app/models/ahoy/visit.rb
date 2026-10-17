# frozen_string_literal: true

module Ahoy
  # One analytics visit (ahoy_visits): a visitor's session on the site, with
  # landing page, referrer, device and, once known, the signed-in user.
  # See documentation/ANALYTICS.md.
  class Visit < ApplicationRecord
    self.table_name = "ahoy_visits"

    has_many :events, class_name: "Ahoy::Event", dependent: :delete_all
    belongs_to :user, optional: true
  end
end
