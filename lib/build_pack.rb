require "pathname"

# General Build Pack module
module BuildPack

  # detects which language pack to use
  # @param [Array] first argument is a String of the build directory
  # @return [LanguagePack] the {LanguagePack} detected
  def self.detect(*args)
    return nil if args.first.nil?
    Dir.chdir(args.first)

    pack = [ Ruby ].detect do |klass|
      klass.use?
    end

    pack ? pack.new(*args) : nil
  end

end

require "build_pack/ruby"
require "build_pack/rails2"
require "build_pack/rails3"
