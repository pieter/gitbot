class Gitweb < PluginBase

  def hook_privmsg_chan(irc, msg)
    if msg =~ /\s*[0-9a-f]{6,40}[\s,?-.]*/
      irc.reply "Unable to look up sha $0"
    end
  end
end
