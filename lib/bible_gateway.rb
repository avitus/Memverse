# coding: utf-8
require 'open-uri'
require 'nokogiri'


class BibleGatewayError < StandardError; end

class BibleGateway
  GATEWAY_URL = "https://www.biblegateway.com"

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
    ### Get text from Facebook description
    fb_desc = doc.css("meta[property='og:description']").first

    if fb_desc.present?
      text = fb_desc['content']

      ### Remove any section heading that may be in description

      # Example description with section heading from Hebrews 10:1
      # "Christ’s Sacrifice Once for All - The law is only a shadow ..."

      headings = doc.css("h3 span, h4 span")

      for heading in headings
        heading.search("sup").remove # remove superscripts

        heading_text = heading.text.strip

        text = text.sub("#{heading_text} - ", "")
        text = text.sub("#{heading_text} ", "")
      end

      # Consistent spacing around em dashes
      text = text.gsub("—", " — ").squeeze(" ").strip
    end

    if text && text.present?
      {:title => "--", :content => text }
    else
      {:title => "--", :content => "--" }
    end

  end
end
