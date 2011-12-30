require "build_pack"
require "build_pack/ruby"

# Rails 2 Language Pack. This is for any Rails 2.x apps.
class BuildPack::Rails2 < BuildPack::Ruby
  # detects if this is a valid Rails 2 app
  # @return [Boolean] true if it's a Rails 2 app
  def self.use?
    super && File.exist?("config/environment.rb")
  end

  def name
    "Ruby/Rails (Rails 2.x)"
  end

  def default_config_vars
    super.merge({
      "RAILS_ENV" => "test",
      "RACK_ENV" => "test"
    })
  end
  
  private
  
  def create_database_yml
    setup_database_url_env
    super
  end
  
  # setup the database url as on environment variable
  def setup_database_url_env
    ENV["DATABASE_URL"] ||= begin
      # need to use a dummy DATABASE_URL here, so rails can load the environment
      scheme =
        if gem_is_bundled?("pg")
          "postgres"
        elsif gem_is_bundled?("mysql")
          "mysql"
        elsif gem_is_bundled?("mysql2")
          "mysql2"
        elsif gem_is_bundled?("sqlite3") || gem_is_bundled?("sqlite3-ruby")
          "sqlite3"
        end
      "#{scheme}://user:pass@127.0.0.1/dbname"
    end
  end
end
