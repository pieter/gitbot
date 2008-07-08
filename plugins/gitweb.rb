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

  def repo_name(ref)
    puts "matching #{ref}"
    if ref =~ /\/([^\/]+)\.git/
      return $1
    else
      return nil
    end
  end

  def lookup_one(url, ref)
    response = Net::HTTP.get_response(URI.parse(url + "/?a=object;h=#{ref}"))
    if response.is_a? Net::HTTPRedirection
      if response["Location"] =~ /\?a=(.*?)($|\&|;)/
        type = $1
        ret = { 
                :ref => ref,
                :type => type,
                :url => shorten(response["Location"]),
                :reponame => repo_name(url)
              }
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
    @loader.lookup(irc, ref, prefix)
  end

  def prettify(r)
    s = "[#{r[:reponame]}::#{r[:ref][0..8]}]: #{r[:url]}"
    if r[:subject]
      s << " -- \"#{r[:subject]}\""
    else
      s << " [#{r[:type]}]"
    end
    s
  end

  def hook_privmsg_chan(irc, msg)
    case msg
    when /\b([0-9a-f]{6,40})\b/
      if lookup = try_lookup(irc, $1)
        irc.puts prettify(lookup)
      end
    when /(?:\s|^)([a-zA-Z0-9]+)?::([^:? ]+?)(\b|::)/
      if lookup = try_lookup(irc, $2, $1)
        irc.puts prettify(lookup)
      else
        irc.reply("I'm sorry, there's no such object #{$2}")
      end
    end
  end

end