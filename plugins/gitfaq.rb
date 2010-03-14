require 'yaml'
require 'open-uri'
require 'cgi'

class Gitfaq < PluginBase

  attr_reader :entries
  attr_accessor :skip_auth

  FAQ_URL = "http://git.wiki.kernel.org/index.php/GitFaq"

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
      begin
        a = open(FAQ_URL).read
        @new_entries = {}
        a.scan(/<span id="(.*)" title="(.*)">/) do |x|
          @new_entries[x[0]] = x[1]
        end
        @entries = @new_entries
      rescue SocketError => e
        $log.puts "Could not fetch FAQ page: #{e}. #{e.message}"
      end
    end
  end

  def load
    load_entries
    return self
  end

  def handle_faq(irc, line, page, explicit = false)
    if Time.now - @last_fetch > 60 * 60 # Refetch after 1 hour
      load_entries
    end

    if f = @entries[page]
      irc.reply_dwim(line, "#{f}. See #{FAQ_URL}##{CGI::escape(page)}")
    elsif explicit
      irc.reply "FAQ entry '#{page}' not found."
    end
  end

  def cmd_faq(irc, line)
    handle_faq(irc, line, line, true)
  end

  def cmd_reload(irc, line)
    load_entries
    irc.reply "Reloading FAQ entries"
  end

  def cmd_list(irc, line)
    irc.reply "Valid topics: #{@entries.keys.sort.join(", ")}"
  end

  def hook_privmsg_chan(irc, msg)
    return unless msg =~ /faq ([\-a-z]+)/
    page = $1

    handle_faq(irc, msg, page)
  end

end
