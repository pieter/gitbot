require 'yaml'
require 'net/http'
require 'uri'
require 'support/htmlentities'

require 'git/channel'

class Git

  attr_accessor :config

  def initialize(configfile = "repositories.yaml")
    # This hack allows us to do @log[server][channel][ref] = ..
    @configfile = configfile
    @log = Hash.new { |x,y| x[y] = Hash.new { |z,q| z[q] = {} } }
    load_config
  end

  def load_config
    @channels = {}
    @config = File.open(@configfile) { |f| YAML::load(f) }
  end

  # Retrieves the git channel for the specific IRC channel
  def git_channel(channel)
    return @channels[channel] if @channels[channel]
    @channels[channel] = Git::Channel.new(@config[channel.server.name][channel.nname])
  end

  def handle_extended(channel, repo, ref, tree)
    l = channel.lookup(ref, repo, tree)

    # Fail loudly if there is no match, but there is a tree or repo specified
    if !l && (tree || repo)
      return { :failed => true, :ref => ref, :file => tree }
    end

    # Fail silently if the ref can't be found
    return unless l

    # Fail silently if there are no matches
    return if l[:failed] && l[:reason] == :nomatches
    
    channel.log(ref)
    return l
  end

  def parse(channel, message)
    channel = git_channel(channel)
    case message
    # Matches <repo branch:Tree>
    when /<(?:([a-zA-Z0-9\-]+) )?([^:?\^\$\~ ]+?)(:([^:?\^\$\~ ]+))?>/
      return handle_extended(channel, $1, $2, $4)
    # Matches an explicit repo
    when /<([a-z]+:[a-zA-Z0-9\/\?=;.\-]+) ([^:?\^\$\~ ]+?)(:([^:?\^\$\~ ]+))?>/
      return unless repo = Git::Source::Source.find_public($1)
      return repo.lookup($2, $4)
    when /\b([0-9a-f]{6,40})\b/
      # Do nothing if has been mentioned < 5 minutes ago
      return if channel.active?($1)
      # Fail silently if necessary
      channel.log($1)
      return channel.lookup($1)
    end
  end
end
