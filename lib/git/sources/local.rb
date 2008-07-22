class Git::Source::Local
  
  Git::Source::Source.add_handler(/file:\/\//, self)
  def self.public?; false; end

  class RepositoryNotFoundError < RuntimeError; end
  def initialize(url)
    url =~ /file:\/\/(.*)/
    @location = $1
    command("git rev-parse")
    ret = $?
    raise RepositoryNotFoundError.new unless ret == 0
  end

  def name
    return File.basename(@location).gsub(/\.git$/, "")
  end

  def matches?(match)
    return name =~ /#{match}/
  end

  def command(cmd)
    `(cd #{@location} && #{cmd})  2>/dev/null`.strip
  end

  def lookup(ref, file)
    if file
      file_add = ":#{file}"
    else
      file_add = ""
    end

    type = command("git cat-file -t #{ref}#{file_add} 2> /dev/null")
    return nil unless $? == 0
    subject = nil
    if type == "commit"
      details = command("git cat-file commit #{ref}")
      if details =~ /\n\n(.+)$/
        subject = $1
      end
    end
    # Point to commitdiff and not commitpage when referring a commit
    return { 
      :file => file,
      :ref => ref,
      :type => type,
      :url => nil,
      :subject => subject,
      :reponame => name
    }
  end
  
end