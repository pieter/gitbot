class Git::Source::Gitweb

  Git::Source::Source.add_handler(/http:\/\//, self)

  def initialize(url)
    @url = url
  end

  def get_details(url, type)
    return {} unless type == "commit" || type == "tag"

    a = Net::HTTP.get(URI.parse(url))
    return { :subject => $1.decode_entities } if a =~ /class=\"title".*?>(.*?)<(span|\/a)/

    # Nothing found
    return {}
  end

  def name
    @url =~ /\/([^\/]+)\.git/
    return $1
  end
  
  def matches?(match)
    return @url =~ match
  end

  def object_url(ref, file)
    if file
      url = @url + ";a=object;f=#{file};hb=#{ref}"
    else
      url = @url + ";a=object;h=#{ref}"
    end
    return URI.parse(url)
  end

  def lookup(ref, file)
    url = object_url(ref, file)
    response = Net::HTTP.get_response(url)
    if response.is_a? Net::HTTPRedirection
      if response["Location"] =~ /\?a=(.*?)($|\&|;)/
        type = $1
        ret = { 
          :file => file,
          :ref => ref,
          :type => type,
          :url => response["Location"],
          :reponame => name
        }
        ret = ret.merge(get_details(response["Location"], type))
        return ret
      end
    end
    return nil
  end

end