#!/usr/local/bin/ruby
#puts "Welcome to ESV bible passage lookup."
#puts "Enter the passage (i.e. Rom 3:15-20) or 'exit' to end."

#ESV access key: 0c93166f4eabf4e4

require 'net/http'

class Esv
  
  def self.request(passage)
    @options = ["include-short-copyright=0",
                "include-headings=0",
                "include-subheadings=0",
                "include-footnotes=0",
                "include-passage-references=0",
                "include-verse-numbers=0",
                "include-first-verse-numbers=0",
                "include-line-breaks=0",
                "output-format=plain-text",
                "include-passage-horizontal-lines=0",
                "include-heading-horizontal-lines=0"].join("&")
    @base_url = "http://www.esvapi.org/v2/rest/passageQuery?key=0c93166f4eabf4e4"
    
    passage = passage.gsub(/\s/, "+")
    passage = passage.gsub(/\:/, "%3A")
    passage = passage.gsub(/\,/, "%2C")
    
    url = @base_url + "&passage=#{passage}&#{@options}"
    verse = Net::HTTP.get(::URI.parse(url))   
    
    return verse.strip
  end
end

#bible = EsvRequest.new(ARGV[0] || 'IP')
#
#while(true)
#  print 'Passage> '
#  passage = gets.strip
#  unless passage==""
#    exit if passage=="exit" || passage=="quit"
#    puts bible.doPassageQuery(passage)
#  end
#end
