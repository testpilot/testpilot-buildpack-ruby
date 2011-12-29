require "tmpdir"
require "build_pack"
require "build_pack/base"

# base Ruby Language Pack. This is for any base ruby app.
class BuildPack::Ruby < BuildPack::Base

  # detects if this is a valid Ruby app
  # @return [Boolean] true if it's a Ruby app
  def self.use?
    File.exist?("Gemfile")
  end

  def name
    "Ruby"
  end


end