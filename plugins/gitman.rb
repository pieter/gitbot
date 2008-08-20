require 'git'
require 'net/http'

class Gitman < PluginBase

  def shorten(url)
    return nil unless url
    http = Net::HTTP.start("tinyurl.com", 80)
    response = http.post("/create.php", "url=#{url}")

    if response.code == "200"
      body = response.read_body
      line = body.split("\n").find { |l| l =~ /hidden name=tinyurl/ }
      i1 = line.index("http")
      i2 = line.rindex("\"")
      return line[i1...i2]
    end
  end

  def handle_manpage(irc, page)
    @current_lookup.join if @current_lookup
    @current_lookup = Thread.new(irc, page) do |irc, page|
      begin
        uri = URI.parse("http://www.kernel.org/pub/software/scm/git/docs/#{page}.html")
        response = Net::HTTP.get_response(uri)
        if response.is_a? Net::HTTPSuccess
          irc.reply "[#{page}]: #{shorten(uri.to_s)}"
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