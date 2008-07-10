require 'git/sources/gitweb'

# A class representing a channel from the Git side, to allow us to maintain
# a list of repositories, a log, etc.
class Git::Channel

  def initialize(urls)
    # For now, we only support Gitweb, but if we extend urls, we can support
    # other types
    @sources = urls.map { |url| Git::Source::Gitweb.new(url) }
    @log = {}
  end
  
  def lookup(ref, match = nil, tree = nil)
    if match
      sources = @sources.select { |x| x.matches? match }
    else
      sources = @sources
    end

    return { :failed => true, :reason => :nomatches } if sources.empty?
    
    sources.each do |source|
      if a = source.lookup(ref, tree)
        return a
      end
    end
    return nil
  end

  def active?(ref)
    ref = ref.to_s[0..6]
    return @log[ref] && (Time.now - @log[ref] < 60 * 5)
  end

  def log(ref)
    ref = ref.to_s[0..6]
    @log[ref] = Time.now
  end
end
