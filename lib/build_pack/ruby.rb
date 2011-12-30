require "tmpdir"
require "build_pack"
require "build_pack/base"

# base Ruby Language Pack. This is for any base ruby app.
class BuildPack::Ruby < BuildPack::Base
  LIBYAML_VERSION     = "0.1.4"
  LIBYAML_PATH        = "libyaml-#{LIBYAML_VERSION}"
  BUNDLER_VERSION     = "1.1.rc.6"
  BUNDLER_GEM_PATH    = "bundler-#{BUNDLER_VERSION}"
  NODE_VERSION        = "0.4.7"
  NODE_JS_BINARY_PATH = "node-#{NODE_VERSION}"

  # detects if this is a valid Ruby app
  # @return [Boolean] true if it's a Ruby app
  def self.use?
    File.exist?("Gemfile")
  end

  def name
    "Ruby"
  end
  
  def default_config_vars
    {
      "LANG"     => "en_US.UTF-8",
      "PATH"     => default_path,
      "GEM_PATH" => slug_vendor_base,
    }
  end
  
  def compile
    Dir.chdir(build_path)
    
    topic("Preparing build environment for #{name} application")
    
    allow_git do
      install_language_pack_gems
      build_bundler
      create_database_yml
      # install_binaries
      # run_assets_precompile_rake_task
    end
  end
  
  private
  
  # decides if we need to install the node.js binary
  # @note execjs will blow up if no JS RUNTIME is detected and is loaded.
  # @return [Array] the node.js binary path if we need it or an empty Array
  def add_node_js_binary
    gem_is_bundled?('execjs') ? [NODE_JS_BINARY_PATH] : []
  end
  
  # list of default gems to vendor into the slug
  # @return [Array] resluting list of gems
  def gems
    [BUNDLER_GEM_PATH]
  end
  
  # installs vendored gems into the slug
  def install_language_pack_gems
    FileUtils.mkdir_p(slug_vendor_base)
    Dir.chdir(slug_vendor_base) do |dir|
      gems.each do |gem|
        run("curl #{VENDOR_URL}/#{gem}.tgz -s -o - | tar xzf -")
      end
      Dir["bin/*"].each {|path| run("chmod 755 #{path}") }
    end
  end
    
  # sets up the environment variables for the build process
  def setup_language_pack_environment
    default_config_vars.each do |key, value|
      ENV[key] ||= value
    end
    ENV["GEM_HOME"] = slug_vendor_base
    ENV["PATH"]     = default_config_vars["PATH"]
  end
  
  # runs bundler to install the dependencies
  def build_bundler
    log("bundle") do
      # bundle_without = ENV["BUNDLE_WITHOUT"] || "development:test"
      bundle_command = "bundle install --path vendor/bundle --binstubs vendor/bin/"

      unless File.exist?("Gemfile.lock")
        error "Gemfile.lock is required. Please run \"bundle install\" locally\nand commit your Gemfile.lock."
      end

      if has_windows_gemfile_lock?
        log("bundle", "has_windows_gemfile_lock")
        File.unlink("Gemfile.lock")
      else
        # using --deployment is preferred if we can
        # bundle_command += " --deployment"
        cache_load ".bundle"
      end

      cache_load "vendor/bundle"

      version = run("env RUBYOPT=\"-r #{syck_hack}\" bundle version").strip
      
      topic("Installing dependencies using #{version}")

      bundler_output = ""
      Dir.mktmpdir("libyaml-") do |tmpdir|
        libyaml_dir = "#{tmpdir}/#{LIBYAML_PATH}"
        install_libyaml(libyaml_dir)

        # need to setup compile environment for the psych gem
        yaml_include   = File.expand_path("#{libyaml_dir}/include")
        yaml_lib       = File.expand_path("#{libyaml_dir}/lib")
        pwd            = run("pwd").chomp
        # we need to set BUNDLE_CONFIG and BUNDLE_GEMFILE for
        # codon since it uses bundler.
        env_vars       = "env BUNDLE_GEMFILE=#{pwd}/Gemfile BUNDLE_CONFIG=#{pwd}/.bundle/config CPATH=#{yaml_include}:$CPATH CPPATH=#{yaml_include}:$CPPATH LIBRARY_PATH=#{yaml_lib}:$LIBRARY_PATH RUBYOPT=\"-r #{syck_hack}\""
        puts "Running: #{bundle_command}"
        bundler_output << pipe("#{env_vars} #{bundle_command} --no-clean 2>&1")

      end

      if $?.success?
        log "bundle", :status => "success"
        puts "Cleaning up the bundler cache."
        run "bundle clean"
        cache_store ".bundle"
        cache_store "vendor/bundle"
      else
        log "bundle", :status => "failure"
        error_message = "Failed to install gems via Bundler."
        
        # Sqlite3 is supported by TestPilot
#         if bundler_output.match(/Installing sqlite3 \([\w.]+\) with native extensions Unfortunately/)
#           error_message += <<ERROR
# 
# 
# Detected sqlite3 gem which is not supported on Heroku.
# http://devcenter.heroku.com/articles/how-do-i-use-sqlite3-for-development
# ERROR
#         end

        error error_message
      end
    end
  end
  
  def create_database_yml
    log("create_database_yml") do
      return unless File.directory?("config")
      topic("Writing config/database.yml to read from DATABASE_URL")
      File.open("config/database.yml", "w") do |file|
        file.puts File.read(build_pack_root.join('support/database.yml'))
      end
    end
  end
  
  
  # RUBYOPT line that requires syck_hack file
  # @return [String] require string if needed or else an empty string
  def syck_hack
    syck_hack_file = File.expand_path(File.join(File.dirname(__FILE__), "../../vendor/syck_hack"))
    ruby_version   = run('ruby -e "puts RUBY_VERSION"').chomp
    # < 1.9.3 includes syck, so we need to use the syck hack
    if Gem::Version.new(ruby_version) < Gem::Version.new("1.9.3")
      "-r #{syck_hack_file}"
    else
      ""
    end
  end
  
  # install libyaml into the LP to be referenced for psych compilation
  # @param [String] tmpdir to store the libyaml files
  def install_libyaml(dir)
    FileUtils.mkdir_p dir
    Dir.chdir(dir) do |dir|
      run("curl #{VENDOR_URL}/#{LIBYAML_PATH}.tgz -s -o - | tar xzf -")
    end
  end
  
  # detects whether the Gemfile.lock contains the Windows platform
  # @return [Boolean] true if the Gemfile.lock was created on Windows
  def has_windows_gemfile_lock?
    lockfile_parser.platforms.detect do |platform|
      /mingw|mswin/.match(platform.os) if platform.is_a?(Gem::Platform)
    end
  end
  
  # detects if a gem is in the bundle.
  # @param [String] name of the gem in question
  # @return [String, nil] if it finds the gem, it will return the line from bundle show or nil if nothing is found.
  def gem_is_bundled?(gem)
    @bundler_gems ||= lockfile_parser.specs.map(&:name)
    @bundler_gems.include?(gem)
  end

  # setup the lockfile parser
  # @return [Bundler::LockfileParser] a Bundler::LockfileParser
  def lockfile_parser
    add_bundler_to_load_path
    require "bundler"
    @lockfile_parser ||= Bundler::LockfileParser.new(File.read("Gemfile.lock"))
  end
  
  # add bundler to the load path
  # @note it sets a flag, so the path can only be loaded once
  def add_bundler_to_load_path
    return if @bundler_loadpath
    $: << File.expand_path(Dir["#{slug_vendor_base}/gems/bundler*/lib"].first)
    @bundler_loadpath = true
  end
    
  # the relative path to the bundler directory of gems
  # @return [String] resulting path
  def slug_vendor_base
    @slug_vendor_base ||= run(%q(ruby -e "require 'rbconfig';puts \"vendor/bundle/#{RUBY_ENGINE}/#{RbConfig::CONFIG['ruby_version']}\"")).chomp
  end
  
  
end