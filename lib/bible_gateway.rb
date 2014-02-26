# coding: utf-8
require 'open-uri'
require 'nokogiri'


class BibleGatewayError < StandardError; end

class BibleGateway
  GATEWAY_URL = "http://www.biblegateway.com"

  VERSIONS = {
    :NNV => "NIV",
    :NAS => "NASB",
    :NKJ => "NKJV",
    :KJV => "KJV",
    :RSV => "Revised Standard Version",
    :NRS => "New Revised Standard Version",
    :ESV => "ESV",
    :NLT => "NLT",
    :CEV => "CEV",
    :HCS => "HCSB",
    :DTL => "DARBY",
    :MSG => "MSG",
    :AMP => "AMP",
    :IRV => "NIRV",
    :UKJ => "KJ21",
    :GRK => "Biblical Greek",
    :NVI => "Nueva Version Internacional",
    :RVR => "Reina-Valera 1960",
    :LSV => "Louis Segond 1910",
    :LND => "La Nuova Diodati",
    :AFR => "Afrikaans 1983 Translation",
    :HSV => "Herziene Statenvertaling",
    :NBV => "De Nieuwe Bijbelvertaling",
    :TMB => "Terjemahan Baru",
    :SPB => "Svenska Folkbibeln"
  }

  def self.versions
    VERSIONS.keys
  end

  attr_accessor :version

  def initialize(version = :NNV)
    self.version = version
  end

  def version=(version)
    # raise BibleGatewayError, 'Unsupported version' unless VERSIONS.keys.include? version
    @version = version
  end

  def lookup(passage)
  	if VERSIONS.keys.include?(version)
		  doc = Nokogiri::HTML(open(passage_url(passage)))
		  scrape_passage(doc)
		else
		  {:title => "--", :content => "--" }
		end
  end

  def passage_url(passage)
    URI.escape "#{GATEWAY_URL}/passage/?search=#{passage}&version=#{VERSIONS[version]}"
  end

  def scrape_passage(doc)
    title = doc.css('h2')[0] ? doc.css('h2')[0].content : "No title"

    # segment = doc.at('font.woj') -- only works for words of Jesus
    # segment = doc.at('div.result-text-style-normal') -- old Biblegateway layout
    # Need to look for text immediately after superscript

    if !(doc.at('sup.versenum')) # if verse is first verse of chapter
      verse_number = doc.at('span.chapternum')
    else
      verse_number = doc.at('sup.versenum')
    end

    if !(doc.at('div.poetry'))
      # For when the verse is not poetry
      segment = verse_number.parent unless !verse_number
    else
      # For when the verse is poetry
      segment = verse_number.parent.parent unless !verse_number
    end

    if segment

      segment.search("sup").remove                 # remove superscripts (verse numbering, footnotes, etc.)
      segment.search("h4").remove                  # remove headings
      segment.search("h5").remove                  # remove headings
      segment.search("div.footnotes").remove       # remove footnotes
      segment.search("div.crossrefs").remove       # remove cross references

      # Converts the special font that BibleGateway uses for 'LORD' and 'God' into 'LORD' and 'GOD'
      segment = segment.to_s.gsub("<span style=\"font-variant: small-caps\" class=\"small-caps\">Lord</span>", "LORD").gsub("<span style=\"font-variant: small-caps\" class=\"small-caps\">God</span>", "GOD")

      # remove html tags, comments, non-breaking space, double spaces, and trailing or leading whitespace
      content = segment.gsub(/<b.+?<\/b>/," ").gsub(/<\/?[^>]*>/, " ").gsub(/<!--.*?-->/, " ").gsub("\u00A0", " ").gsub(/\s{2,}/, " ").strip
      content = content.gsub(/^\d{1,3}/," ").strip # remove chapter numbers (if present)
    else
      {:title => "--", :content => "--" }
    end
    {:title => title, :content => content }
  end
end
