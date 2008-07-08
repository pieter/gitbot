require 'yaml'
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

  def get_details(url, type)
    return {} unless type == "commit" || type == "tag"

    a = Net::HTTP.get(URI.parse(url))
    return { :subject => $1 } if a =~ /class=\"title".*?>(.*?)<(span|\/a)/

    # Nothing found
    return {}
  end

  def repo_name(ref)
    if ref =~ /\/([^\/]+)\.git/
      return $1
    else
      return nil
    end
  end

  def lookup_one(url, ref, file)
    if file
      url = url + "/?a=object;f=#{file};hb=#{ref}"
    else
      url += "/?a=object;h=#{ref}"
    end
    response = Net::HTTP.get_response(URI.parse(url))
    if response.is_a? Net::HTTPRedirection
      if response["Location"] =~ /\?a=(.*?)($|\&|;)/
        type = $1
        ret = { 
          :file => file,
          :ref => ref,
          :type => type,
          :url => shorten(response["Location"]),
          :reponame => repo_name(url)
        }
        ret = ret.merge(get_details(response["Location"], type))
        return ret
      end
    end
    return nil
  end

  def lookup(server, channel, ref, match = nil, file=nil)
    urls = config[server][channel] rescue []
    urls.each do |url|
      next if match and url !~ match
      if a = lookup_one(url, ref, file)
        return a
      end
    end
    return nil
  end

  def parse(server, channel, message)
    case message
    when /<([a-zA-Z0-9\-]+ )?([^:? ]+?)(:([^:? ]+))?>/
      # If a reponame is specified, match on /repo.git
      match = $1 ? /\/#{$1[0..-2]}\.git/ : nil
      if l = lookup(server, channel, $2, match, $4)
        return l
      elsif $1 || $4
        # Return an explicit failure
        return { :failed => true, :ref => $2, :file => $4 }
      else
        return nil
      end
    when /\b([0-9a-f]{6,40})\b/
      # Fail silently if necessary
      return lookup(server, channel, $1)
    end
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

  def prettify(r)
    # Use the filename if a file/tree was provided, otherwise use the ref
    if r[:file]
      name = File.basename(r[:file])
    else
      name = r[:ref][0..8]
    end
    s = "[#{r[:reponame]} #{name}]: #{r[:url]}"
    if r[:subject]
      s << " -- \"#{r[:subject]}\""
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