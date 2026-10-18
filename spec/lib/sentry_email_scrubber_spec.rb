# frozen_string_literal: true

require 'rails_helper'
require_relative '../../lib/sentry_email_scrubber'

RSpec.describe SentryEmailScrubber do
  describe '.scrub' do
    it "redacts the address in Postmark's error message and keeps the rest" do
      expect(described_class.scrub("Invalid 'To' address: 'someone@example.com'."))
        .to eq("Invalid 'To' address: '[email redacted]'.")
    end

    # Postmark rejects malformed addresses, so the ones it reports often lack a TLD
    it 'redacts an address without a top-level domain' do
      expect(described_class.scrub("Invalid 'To' address: 'suppressed@example'."))
        .to eq("Invalid 'To' address: '[email redacted]'.")
    end

    it 'redacts every address in a SQL statement' do
      sql = "SELECT `users`.* FROM `users` WHERE `users`.`email` IN ('a.b+tag@example.co.uk', 'c@d.org')"

      expect(described_class.scrub(sql))
        .to eq("SELECT `users`.* FROM `users` WHERE `users`.`email` IN ('[email redacted]', '[email redacted]')")
    end

    it 'redacts URL-encoded addresses in paths and query strings' do
      expect(described_class.scrub('/users/password/new?email=first.last%2Btag%40example.com&x=1'))
        .to eq('/users/password/new?email=[email redacted]&x=1')
    end

    # gsub raises on invalid UTF-8, and Sentry drops the event if before_send raises
    it 'redacts addresses in strings with invalid byte sequences' do
      expect(described_class.scrub("bad \xFF byte from someone@example.com"))
        .to eq("bad � byte from [email redacted]")
    end

    it 'leaves text without an address unchanged' do
      text = 'User 42 mentioned @admin in a post'

      expect(described_class.scrub(text)).to eq(text)
    end

    it 'recurses into hashes and arrays, including keys' do
      data = { params: { 'user' => { 'email' => 'x@y.com', 'id' => 7 } }, 'x@y.com' => ['z@w.net', 3] }

      expect(described_class.scrub(data)).to eq(
        params: { 'user' => { 'email' => '[email redacted]', 'id' => 7 } },
        '[email redacted]' => ['[email redacted]', 3]
      )
    end

    it 'returns other values as they are' do
      expect([42, nil, :sym, true].map { |value| described_class.scrub(value) }).to eq([42, nil, :sym, true])
    end
  end
end
