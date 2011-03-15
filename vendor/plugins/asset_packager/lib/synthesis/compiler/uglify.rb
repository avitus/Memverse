module Synthesis
  module Compiler
    class Uglify
  
      class << self
        
        def description
          'UglifyJS running on Node.js.'
        end
            
        def compress(source)
      
          raise CompileError.new("You need to install node.js in order to compile using UglifyJS.") unless %x[which node].length > 1
          IO.popen("cd #{Pathname.new(File.join(File.dirname(__FILE__),'node-js')).realpath} && node uglify.js", "r+") do |io|
            io.write(source)
            io.close_write
            compressed_source = io.read
          end
      
        end
    
      end
  
    end
  end
end

Synthesis::AssetPackage.add_compiler(Synthesis::Compiler::Uglify)