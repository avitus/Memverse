require 'yaml'

module Synthesis
  
  module Compiler
    class CompileError < RuntimeError; end
  end
    
  class AssetPackage
            
    @asset_base_path    = "#{Rails.root}/public"
    @asset_packages_yml = File.exists?("#{Rails.root}/config/asset_packages.yml") ? YAML.load_file("#{Rails.root}/config/asset_packages.yml") : nil
    @options = @asset_packages_yml['options'] || {
      'compilers' => [ 'closure', 'uglify' ]
    }

    class << self
      attr_accessor :asset_base_path,
                    :asset_packages_yml,
                    :options

      attr_writer   :merge_environments,
                    :add_compiler
      
      def add_compiler(c)
        @compilers ||= []
        begin
          c = c.constantize if c.is_a?(String)
          @compilers << {
            :class => c,
            :description => c.description
          }
        rescue NameError => e
          raise "You've specified a non-existent compiler '#{c}' when calling \#add_compiler, with the error: #{e}"
        end
      end
      
      def compilers
        @compilers ||= []
      end
      
      def asset_list
        @asset_list ||= @asset_packages_yml.reject{ |k,v| k == 'options' }
      end

      def merge_environments
        @merge_environments ||= ['production']
      end

      def parse_path(path)
        /^(?:(.*)\/)?([^\/]+)$/.match(path).to_a
      end

      def find_by_type(asset_type)
        asset_list[asset_type].map { |p| self.new(asset_type, p, compilers, options) }
      end

      def find_by_target(asset_type, target)
        package_hash = asset_list[asset_type].find {|p| p.keys.first == target }
        package_hash ? self.new(asset_type, package_hash, compilers, options) : nil
      end

      def find_by_source(asset_type, source)
        path_parts = parse_path(source)
        package_hash = asset_list[asset_type].find do |p|
          key = p.keys.first
          p[key].include?(path_parts[2]) && (parse_path(key)[1] == path_parts[1])
        end
        package_hash ? self.new(asset_type, package_hash, compilers, options) : nil
      end

      def targets_from_sources(asset_type, sources)
        package_names = Array.new
        sources.each do |source|
          package = find_by_target(asset_type, source) || find_by_source(asset_type, source)
          package_names << (package ? package.current_file : source)
        end
        package_names.uniq
      end

      def sources_from_targets(asset_type, targets)
        source_names = Array.new
        targets.each do |target|
          package = find_by_target(asset_type, target)
          source_names += (package ? package.sources.collect do |src|
            package.target_dir.gsub(/^(.+)$/, '\1/') + src
          end : target.to_a)
        end
        source_names.uniq
      end

      def build_all
        asset_list.keys.each do |asset_type|
          asset_list[asset_type].each { |p| self.new(asset_type, p, compilers, options).build }
        end
      end

      def delete_all
        asset_list.keys.each do |asset_type|
          asset_list[asset_type].each { |p| self.new(asset_type, p, compilers, options).delete_previous_build }
        end
      end

      def create_yml
        unless File.exists?("#{Rails.root}/config/asset_packages.yml")
          asset_yml = Hash.new
          
          asset_yml['options'] = Hash.new
          asset_yml['options']['compilers'] = compilers

          asset_yml['javascripts'] = [{"base" => build_file_list("#{Rails.root}/public/javascripts", "js")}]
          asset_yml['stylesheets'] = [{"base" => build_file_list("#{Rails.root}/public/stylesheets", "css")}]

          File.open("#{Rails.root}/config/asset_packages.yml", "w") do |out|
            YAML.dump(asset_yml, out)
          end

          log "config/asset_packages.yml example file created!"
          log "Please reorder files under 'base' so dependencies are loaded in correct order."
        else
          log "config/asset_packages.yml already exists. Aborting task..."
        end
      end

    end

    # instance methods
    attr_accessor :asset_type, :target, :target_dir, :sources, :compilers

    def initialize(asset_type, package_hash, compilers, options = {})
      target_parts = self.class.parse_path(package_hash.keys.first)
      @target_dir = target_parts[1].to_s
      @target = target_parts[2].to_s
      @sources = package_hash[package_hash.keys.first]
      @asset_type = asset_type
      @asset_path = "#{self.class.asset_base_path}/#{@asset_type}#{@target_dir.gsub(/^(.+)$/, '/\1')}"
      @extension = get_extension
      @file_name = "#{@target}_packaged.#{@extension}"
      @full_path = File.join(@asset_path, @file_name)
      @latest_mtime = get_latest_mtime
      @compilers = sort_and_clean_compilers(compilers, options)
    end
    
    # Remove compilers that weren't specified in the options, and sort based on stated order in
    # asset_packages.yml, unless we don't have the 'compilers' options specified at all.
    def sort_and_clean_compilers(compilers, options)
      return compilers unless options['compilers'] && options['compilers'].length > 0
      compilers.select!{ |c| options['compilers'].include?(c[:class].to_s.demodulize.downcase) }
      compilers.sort_by!{ |c| options['compilers'].index(c[:class].to_s.demodulize.downcase) }
    end

    def package_exists?
      File.exists?(@full_path)
    end

    def current_file
      build unless package_exists?

      path = @target_dir.gsub(/^(.+)$/, '\1/')
      "#{path}#{@target}_packaged"
    end

    def build
      delete_previous_build
      create_new_build
    end

    def delete_previous_build
      File.delete(@full_path) if File.exists?(@full_path)
    end

    private
    
      def create_new_build
        new_build_path = "#{@asset_path}/#{@target}_packaged.#{@extension}"
        if File.exists?(new_build_path)
          log "Latest version already exists: #{new_build_path}"
        else
          File.open(new_build_path, "w") {|f| f.write(compressed_file) }
          File.utime(0, @latest_mtime, new_build_path)
          log "Created #{new_build_path}"
        end
      end

      def merged_file
        merged_file = ""
        @sources.each {|s|
          File.open("#{@asset_path}/#{s}.#{@extension}", "r") { |f|
            merged_file += f.read + "\n"
          }
        }
        merged_file
      end

      # Store the latest mtime so that we can attach it to the merged archive.
      # This allows the Rails asset IDs to work as intended for caching purposes -
      # if none of the files in the archive have been modified since the last build,
      # then the new build (typically done at deploy time) will keep the same mtime
      # (and Rails asset ID).
      #
      def get_latest_mtime
        return @sources.collect{ |s| File.mtime("#{@asset_path}/#{s}.#{@extension}") }.max
      end

      def compressed_file
        case @asset_type
          when 'javascripts' then compress_js(merged_file)
          when 'stylesheets' then compress_css(merged_file)
        end
      end

      def compress_js(source)
        raise Compiler::CompileError.new("No compilers available.") unless @compilers.length > 0
        @compilers.each do |c|
          begin
            log("Compressing with #{c[:description]}...")
            return c[:class].compress(source)
          rescue Compiler::CompileError => e
            log("Errored out with: #{e}")
          end
        end
        raise Compiler::CompileError.new("All available compilers failed.")
      end

      def compress_css(source)
        source.gsub!(/\s+/, " ")           # collapse space
        source.gsub!(/\/\*(.*?)\*\//, "")  # remove comments - caution, might want to remove this if using css hacks
        source.gsub!(/\} /, "}\n")         # add line breaks
        source.gsub!(/\n$/, "")            # remove last break
        source.gsub!(/ \{ /, " {")         # trim inside brackets
        source.gsub!(/; \}/, "}")          # trim inside brackets
        
        # add timestamps to images in css
        source.gsub!(/url\(['"]?([^'"\)]+?(?:gif|png|jpe?g))['"]?\)/i) do |match|
          file = $1
          path = File.join(Rails.root, 'public')
          if file.starts_with?('/')
            path = File.join(path, file) 
          else
            path = File.join(path, 'stylesheets', file)
          end
          match.gsub(file, "#{file}?#{File.new(path).mtime.to_i}")
        end
        
        source
      end

      def get_extension
        case @asset_type
          when 'javascripts' then 'js'
          when 'stylesheets' then 'css'
        end
      end

      def log(message)
        self.class.log(message)
      end

      def self.log(message)
        puts message
      end

      def self.build_file_list(path, extension)
        re = Regexp.new(".#{extension}\\z")
        file_list = Dir.new(path).entries.delete_if { |x| ! (x =~ re) }.map {|x| x.chomp(".#{extension}")}
        # reverse javascript entries so prototype comes first on a base Rails app.
        file_list.reverse! if extension == "js"
        file_list
      end
  end
end

# Load all compilers.
Dir[File.join(File.dirname(__FILE__),'compiler','*.rb')].each {|file| require file }