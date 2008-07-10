class Git; module Source; end; end
class Git::Source::Source

  class << self

    def add_handler(match, klass)
      @handles ||= {}
      @handles[match] = klass
    end

    def create(url)
      @handles.each do |match, klass|
        if url =~ match
          return klass.new(url)
        end
      end
      raise RuntimeError.new("Could not find a handler for this url: #{url}")
    end

  end
end

require 'git/sources/gitweb'
require 'git/sources/repo'