module Synthesis
  module Compiler
    class Closure
  
      class << self
        
        def description
          "Google's Closure Compiler"
        end
                    
        def compress(source)
      
          require 'net/http'
          require 'uri'

          url = URI.parse('http://closure-compiler.appspot.com/compile')
          req = Net::HTTP::Post.new(url.path)
          req.set_form_data(
          {
            'js_code'=> source,
            'compilation_level' => 'SIMPLE_OPTIMIZATIONS',
            'output_format' => 'text',
            'output_info' => 'compiled_code'
          })

          res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
          
          case res
          when Net::HTTPSuccess, Net::HTTPRedirection
            return res.body
          else
            raise CompileError.new("HTTP request didn't return 200 when compiling Javascript with Google's Closure Compiler.")
          end
                
        end
    
      end
      
    end
  end
end

Synthesis::AssetPackage.add_compiler(Synthesis::Compiler::Closure)