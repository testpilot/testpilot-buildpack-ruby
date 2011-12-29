require "build_pack"
require "pathname"
require "yaml"
require "digest/sha1"

Encoding.default_external = Encoding::UTF_8 if defined?(Encoding)

# abstract class that all the Ruby based Language Packs inherit from
class BuildPack::Base
  attr_reader :build_path, :cache_path

  # changes directory to the build_path
  # @param [String] the path of the build dir
  # @param [String] the path of the cache dir
  def initialize(build_path, cache_path=nil)
    @build_path = build_path
    @cache_path = cache_path
    @id = Digest::SHA1.hexdigest("#{Time.now.to_f}-#{rand(1000000)}")[0..10]

    Dir.chdir build_path
  end

  def self.===(build_path)
    raise "must subclass"
  end

  # name of the Language Pack
  # @return [String] the result
  def name
    raise "must subclass"
  end

  # config vars to be set on first push.
  # @return [Hash] the result
  # @not: this is only set the first time an app is pushed to.
  def default_config_vars
    raise "must subclass"
  end

  # process types to provide for the app
  # Ex. for rails we provide a web process
  # @return [Hash] the result
  def default_process_types
    raise "must subclass"
  end

  # this is called to build the slug
  def compile
  end
  
  # log output
  # Ex. log "some_message", "here", :someattr="value"
  def log(*args)
    args.concat [:id => @id]
    args.concat [:framework => self.class.to_s.split("::").last.downcase]

    start = Time.now.to_f
    log_internal args, :start => start

    if block_given?
      begin
        ret = yield
        finish = Time.now.to_f
        log_internal args, :status => "complete", :finish => finish, :elapsed => (finish - start)
        return ret
      rescue StandardError => ex
        finish = Time.now.to_f
        log_internal args, :status => "error", :finish => finish, :elapsed => (finish - start), :message => ex.message
        raise ex
      end
    end
  end
  
  private
  
  # sets up the environment variables for the build process
  def setup_language_pack_environment
  end

  def log_internal(*args)
    message = build_log_message(args)
    %x{ logger -p user.notice -t "slugc[$$]" "buildpack-ruby #{message}" }
  end

  def build_log_message(args)
    args.map do |arg|
      case arg
        when Float then "%0.2f" % arg
        when Array then build_log_message(arg)
        when Hash  then arg.map { |k,v| "#{k}=#{build_log_message([v])}" }.join(" ")
        else arg
      end
    end.join(" ")
  end
  
  # display error message and stop the build process
  # @param [String] error message
  def error(message)
    Kernel.puts " !"
    message.split("\n").each do |line|
      Kernel.puts " !     #{line.strip}"
    end
    Kernel.puts " !"
    log "exit", :error => message
    exit 1
  end

  # run a shell comannd and pipe stderr to stdout
  # @param [String] command to be run
  # @return [String] output of stdout and stderr
  def run(command)
    %x{ #{command} 2>&1 }
  end

  # run a shell command and stream the ouput
  # @param [String] command to be run
  def pipe(command)
    output = ""
    IO.popen(command) do |io|
      until io.eof?
        buffer = io.gets
        output << buffer
        puts buffer
      end
    end

    output
  end

  # display a topic message
  # (denoted by ----->)
  # @param [String] topic message to be displayed
  def topic(message)
    Kernel.puts "-----> #{message}"
    $stdout.flush
  end
  
  # display a message in line
  # (indented by 6 spaces)
  # @param [String] message to be displayed
  def puts(message)
    message.split("\n").each do |line|
      super "       #{line.strip}"
    end
    $stdout.flush
  end
  
  
  
end