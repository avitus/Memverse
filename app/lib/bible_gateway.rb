require 'open-uri'
require 'nokogiri'

class BibleGatewayError < StandardError; end

class BibleGateway
  GATEWAY_URL = 'https://www.biblegateway.com'

  VERSIONS = {
    NNV: 'NIV',
    NAS: 'NASB',
    NKJ: 'NKJV',
    KJV: 'KJV',
    RSV: 'Revised Standard Version',
    NRS: 'New Revised Standard Version',
    ESV: 'ESV',
    NLT: 'NLT',
    CEV: 'CEV',
    HCS: 'HCSB',
    DTL: 'DARBY',
    MSG: 'MSG',
    AMP: 'AMP',
    IRV: 'NIRV',
    UKJ: 'KJ21',
    GRK: 'Biblical Greek',
    NVI: 'Nueva Version Internacional',
    RVR: 'Reina-Valera 1960',
    LSV: 'Louis Segond 1910',
    LND: 'La Nuova Diodati',
    AFR: 'Afrikaans 1983 Translation',
    HSV: 'Herziene Statenvertaling',
    NBV: 'De Nieuwe Bijbelvertaling',
    TMB: 'Terjemahan Baru',
    SPB: 'Svenska Folkbibeln'
  }

  def self.versions
    VERSIONS.keys
  end

  attr_accessor :version

  def initialize(version = :NNV)
    self.version = version
  end

  attr_writer :version

  def lookup(passage)
    return { title: '--', content: '--' } unless VERSIONS.keys.include?(version)

    attempts = 0

    begin
      attempts += 1
      doc = Nokogiri::HTML(URI.open(passage_url(passage)))
      scrape_passage(doc)
    rescue OpenURI::HTTPError => e
      # Gracefully handle transient upstream failures (e.g. 503)
      if e.io&.status&.first.to_i >= 500 && attempts < 3
        sleep(attempts) # simple backoff
        retry
      end

      Sentry.set_tags(service: 'bible_gateway', http_status: e.io&.status&.first) if defined?(Sentry)
      Rails.logger.warn("BibleGateway lookup failed: #{e.message}") if defined?(Rails)
      { title: '--', content: '--' }
    rescue StandardError => e
      Rails.logger.error("BibleGateway unexpected error: #{e.class}: #{e.message}") if defined?(Rails)
      { title: '--', content: '--' }
    end
  end

  def passage_url(passage)
    "#{GATEWAY_URL}/passage/?search=#{URI.encode_www_form_component(passage)}&version=#{URI.encode_www_form_component(VERSIONS[version])}"
  end

  def scrape_passage(doc)
    ### Get text from Facebook description
    fb_desc = doc.css("meta[property='og:description']").first

    if fb_desc.present?
      text = fb_desc['content']

      ### Remove any section heading that may be in description

      # Example description with section heading from Hebrews 10:1
      # "Christ’s Sacrifice Once for All - The law is only a shadow ..."

      headings = doc.css('h3 span, h4 span')

      for heading in headings
        heading.search('sup').remove # remove superscripts

        heading_text = heading.text.strip

        text = text.sub("#{heading_text} - ", '')
        text = text.sub("#{heading_text} ", '')
      end

      # Consistent spacing around em dashes
      text = text.gsub('—', ' — ').squeeze(' ').strip
    end

    if text && text.present?
      { title: '--', content: text }
    else
      { title: '--', content: '--' }
    end
  end
end
