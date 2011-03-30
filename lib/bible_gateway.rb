# coding: utf-8
require 'open-uri'
require 'nokogiri'

class BibleGatewayError < StandardError; end
  
class BibleGateway
  GATEWAY_URL = "http://www.biblegateway.com"
   
  VERSIONS = { 
    :NIV => "NIV1984",
    :NNV => "NIV",
    :NAS => "NASB", 
    :NKJ => "NKJV", 
    :KJV => "KJV",
    :RSV => "Revised Standard Version",
    :NRS => "New Revised Standard Version",                          
    :ESV => "ESV",
    :NLT => "NLT",
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
  
  def initialize(version = :NIV)
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

  private
    def passage_url(passage)
      URI.escape "#{GATEWAY_URL}/passage/?search=#{passage}&version=#{VERSIONS[version]}"
    end

    def scrape_passage(doc)
      title = doc.css('h2')[0] ? doc.css('h2')[0].content : "No title"
      segment = doc.at('div.result-text-style-normal')
      
      if segment
	    segment.search('sup.xref').remove 				# remove cross reference links
	    segment.search('sup.footnote').remove 			# remove footnote links
	    segment.search("div.crossrefs").remove 			# remove cross references
	    segment.search("div.footnotes").remove 			# remove footnotes
	    segment.search('sup.versenum').remove				# remove verse numbering
	     
	    # remove headings, html tags, comments, non-breaking space, and trailing or leading whitespace
	    content = segment.inner_html.gsub(/<h(4|5).+?<\/h(4|5)>/,"").gsub(/<b.+?<\/b>/,"").gsub(/<\/?[^>]*>/, "").gsub(/<!--.*?-->/, '').gsub("\u00A0", "").gsub(/\s{2,}/, " ").strip
      else
      	{:title => "--", :content => "--" }
      end
      {:title => title, :content => content }
    end
end