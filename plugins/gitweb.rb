require 'gitweb'

class Gitweb < PluginBase

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
    @loader = GitwebLoader.new($config["plugins/gitweb/configfile"])
  end

  def prettify(r)
    # Use the filename if a file/tree was provided, otherwise use the ref
    if r[:file]
      name = File.basename(r[:file])
    else
      name = r[:ref][0..8]
    end
    s = "[#{r[:reponame]} #{name}]: #{r[:url]}"
    if r[:subject]
      s << " -- #{r[:subject]}"
    else
      s << " [#{r[:type]}]"
    end
    s
  end

  def hook_privmsg_chan(irc, msg)
    return unless r = @loader.parse(irc.server.name, irc.channel.name, msg)
    if r[:failed]
      object = r[:ref]
      object += ":#{r[:file]}" if r[:file]
      irc.reply("I'm sorry, there's no such object: #{object}.")
      return
    end
    irc.puts prettify(r)
  end

end