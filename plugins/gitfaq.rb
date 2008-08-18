require 'yaml'
require 'open-uri'
require 'cgi'

class Gitfaq < PluginBase

  attr_reader :entries
  attr_accessor :skip_auth

  FAQ_URL = "http://frim.frim.nl/gitfaq.html"

  def authed?(irc)
    unless $user.caps(irc, 'faq', 'op', 'owner').any? or skip_auth
      irc.reply "You aren't allowed to use this command"
      return false
    end
    true
  end

  def initialize(*args)
    $config.merge(
    'plugins' => {
      :dir => true,
      'gitfaq' => {
        :dir => true,
        :help => 'Settings for the gitweb plugin.',
        'phrasesfile' => 'The file to read repositories from'
      }
    }
    )
    super(*args)
  end

  def load_entries
    @last_fetch = Time.now
    @run_thread = Thread.new do
      @entries = {}
      a = open(FAQ_URL).read
      a.scan(/<!-- GitLink\[(.*)\] (.*) -->/) do |x|
        @entries[x[0]] = x[1]
      end
    end
  end

  def load
    load_entries
    return self
  end

  def cmd_faq(irc, line)
    if Time.now - @last_fetch > 60 * 60 # Refetch after 1 hour
      load_entries
    end

    if f = @entries[line]
      irc.reply "#{line}: #{f}. See #{FAQ_URL}##{CGI::escape(line)}"
    else
      irc.reply "FAQ entry '#{line}' not found."
    end
  end

  def cmd_reload(irc, line)
    load_entries
    irc.reply "Reloading FAQ entries"
  end
end