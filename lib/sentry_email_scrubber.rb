# frozen_string_literal: true

# Sentry before_send hook that redacts email addresses from every event.
#
# send_default_pii keeps request bodies and cookies out, but addresses still
# reach Sentry through exception messages (Postmark names the recipient),
# breadcrumbs (mysql2 SQL carries literal values, controller params are not
# filtered for email) and request headers such as Referer. Scrubbing here, once
# per sent event, is cheaper than scrubbing every breadcrumb as it is recorded.
module SentryEmailScrubber
  REDACTED = '[email redacted]'

  # Permissive on purpose: Postmark reports malformed addresses (often without
  # a TLD), and URLs carry the @ encoded as %40. The quote is left out of the
  # local part so "'someone@example.com'" keeps its quotes.
  EMAIL_PATTERN = /[[:alnum:]._%+-]+(?:@|%40)[[:alnum:]-]+(?:\.[[:alnum:]-]+)*/

  EVENT_FIELDS = %i[message transaction extra contexts tags user].freeze
  REQUEST_FIELDS = %i[url query_string data cookies headers env].freeze

  class << self
    def call(event, _hint)
      scrub_fields(event, EVENT_FIELDS)
      scrub_fields(event.request, REQUEST_FIELDS) if event.request
      scrub_exceptions(event)
      scrub_breadcrumbs(event)
      event
    end

    def scrub(value)
      case value
      when String then scrub_string(value)
      when Hash then value.to_h { |key, val| [scrub(key), scrub(val)] }
      when Array then value.map { |val| scrub(val) }
      else value
      end
    end

    private

    def scrub_string(string)
      return string unless string.include?('@') || string.include?('%40')

      # gsub raises on invalid byte sequences, which would drop the whole event
      string = string.scrub unless string.valid_encoding?
      string.gsub(EMAIL_PATTERN, REDACTED)
    end

    def scrub_fields(object, fields)
      fields.each do |field|
        value = object.public_send(field)
        object.public_send(:"#{field}=", scrub(value)) unless value.nil?
      end
    end

    def scrub_exceptions(event)
      return unless event.respond_to?(:exception) && event.exception

      event.exception.values.each { |exception| exception.value = scrub(exception.value) }
    end

    def scrub_breadcrumbs(event)
      event.breadcrumbs&.each do |crumb|
        crumb.message = scrub(crumb.message) if crumb.message
        crumb.data = scrub(crumb.data)
      end
    end
  end
end
