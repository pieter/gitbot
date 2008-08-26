require 'git'
require 'net/http'
require 'support/tinyurl'

class Gitman < PluginBase

  def handle_manpage(irc, page)
    @current_lookup.kill if @current_lookup
    @current_lookup = Thread.new(irc, page) do |irc, page|
      begin
        uri = URI.parse("http://www.kernel.org/pub/software/scm/git/docs/#{page}.html")
        response = Net::HTTP.get_response(uri)
        if response.is_a? Net::HTTPSuccess
          irc.reply "[#{page}]: #{TinyURL.tiny(uri.to_s)}"
        end
      rescue SocketError
        $log.puts "Could not look up entry #{page}"
      end
    end
  end

  def hook_privmsg_chan(irc, msg)
    return unless msg =~ /man (git[\-a-z]+)/
    page = $1
    handle_manpage(irc, page)
  end

end