require 'git'
require 'support/tinyurl'

class Gitweb < PluginBase

  # Remove the "Git" constant and reload them
  def before_reload
    Object.class_eval do
      remove_const "Git"
    end
    $".delete_if { |x| x =~ /^git/}
    require 'git.rb'
  end

  def initialize(*args)
    $config.merge(
    'plugins' => {
      :dir => true,
      'gitweb' => {
        :dir => true,
        :help => 'Settings for the gitweb plugin.',
        'configfile' => 'The file to read repositories from'
      }
    }
    )
    super(*args)
  end

  def load
    @loader = Git.new($config["plugins/gitweb/configfile"])
  end

  def prettify(r)
    # Use the filename if a file/tree was provided, otherwise use the ref
    if r[:file]
      name = File.basename(r[:file])
    else
      name = r[:ref][0..8]
    end
    s = "[#{r[:reponame]} #{name}]: #{TinyURL.tiny(r[:url])}"
    if r[:subject]
      s << " -- #{r[:subject]}"
    else
      s << " [#{r[:type]}]"
    end
    s
  end

  def hook_privmsg_chan(irc, msg)
    return unless r = @loader.parse(irc.channel, msg)
    if r[:failed]
      object = r[:ref]
      object += ":#{r[:file]}" if r[:file]
      irc.reply("I'm sorry, there's no such object: #{object}.")
      return
    end
    irc.puts prettify(r)
  end

end