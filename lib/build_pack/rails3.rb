require "build_pack"
require "build_pack/rails2"

# Rails 3 Language Pack. This is for any Rails 3.x apps.
class BuildPack::Rails3 < BuildPack::Rails2
  # detects if this is a valid Rails 3 app
  # @return [Boolean] true if it's a Rails 3 app
  def self.use?
    super &&
      File.exists?("config/application.rb") &&
      File.read("config/application.rb") =~ /Rails::Application/
  end

  def name
    "Ruby/Rails (Rails 3.x)"
  end
    
end
