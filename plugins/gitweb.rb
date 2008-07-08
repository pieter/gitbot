require 'net/http'
require 'uri'

class GitwebLoader
  
  def initialize(configfile)
    @config = File.open(configfile) { |f| YAML::load(f) }
  end

  def shorten(url)
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
  
  def config
    @config ||= File.open("repositories.yaml") { |f| YAML::load(f) }
  end

  def get_details(url, type, ref)
    return {} unless type == "commit" || type == "tag"

    a = Net::HTTP.get(URI.parse(url + "/?a=#{type};h=#{ref}"))
    return { :subject => $1 } if a =~ /class=\"title".*?>(.*?)<(span|\/a)/

    # Nothing found
    return {}
  end

  def lookup_one(url, ref)
    response = Net::HTTP.get_response(URI.parse(url + "/?a=object;h=#{ref}"))
    if response.is_a? Net::HTTPRedirection
      if response["Location"] =~ /\?a=(.*?)($|\&|;)/
        type = $1
        ret = { :type => type, :url => shorten(response["Location"]) }
        ret = ret.merge(get_details(url, type, ref))
        return ret
      end
    end
    return nil
  end

  def lookup(irc, ref, match = nil)
    urls = config[irc.server.name][irc.channel.name] rescue []
    urls.each do |url|
      next if match and url !~ match
      if a = lookup_one(url, ref)
        return a
      end
    end
    return nil
  end

end


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

  def try_lookup(irc, ref, prefix=nil)
    prefix = /\/#{prefix}/ if prefix
    if r = @loader.lookup(irc, ref, prefix)
      s = "#{ref[0..8]} is a #{r[:type]}. Gitweb: #{r[:url]}"
      s << " -- #{r[:subject]}" if r[:subject]
      irc.reply s
      return true
    end
    return nil
  end

  def hook_privmsg_chan(irc, msg)
    if msg =~ /\b([0-9a-f]{6,40})\b/
      try_lookup(irc, $1)
    elsif msg =~ /\b([a-zA-Z0-9]+)?::([^:? ]+?)(\b|::)/
      unless try_lookup(irc, $2, $1)
        irc.reply("I'm sorry, there's no such object #{$2}")
      end
    end
  end

end