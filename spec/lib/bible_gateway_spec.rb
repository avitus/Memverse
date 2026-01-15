require 'rails_helper'

RSpec.describe BibleGateway do
  let(:gateway) { described_class.new(:KJV) }

  describe '#lookup' do
    it 'gracefully handles HTTP 503 errors' do
      io = double('io', status: ['503', 'Service Unavailable'])
      error = OpenURI::HTTPError.new('503 Service Unavailable', io)

      allow(URI).to receive(:open).and_raise(error)

      result = gateway.lookup('John 3:16')

      expect(result).to eq(title: '--', content: '--')
    end

    it 'retries on transient 5xx errors' do
      io = double('io', status: ['503', 'Service Unavailable'])
      error = OpenURI::HTTPError.new('503 Service Unavailable', io)
      html = '<html><meta property="og:description" content="For God so loved the world" /></html>'

      allow(URI).to receive(:open).and_raise(error).once
      allow(URI).to receive(:open).and_return(StringIO.new(html))

      result = gateway.lookup('John 3:16')

      expect(result[:content]).to include('For God so loved the world')
    end
  end
end
