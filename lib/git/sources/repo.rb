require 'git/sources/gitweb'

class Git::Source::Repo < Git::Source::Gitweb
  
  Git::Source::Source.add_handler(/repo:/, self)
  def self.public?; true; end

  attr_accessor :name
  def initialize(url)
    url =~/repo:(.*).git/
    @name = $1
    @url = "http://repo.or.cz/w/" + @name + ".git"
  end

  def object_url(ref, file)
    if file
      url = @url + "/?a=object;f=#{file};hb=#{ref}"
    else
      url = @url + "/?a=object;h=#{ref}"
    end
    return URI.parse(url)
  end
  
end