require 'yaml'

class Gitfaq < PluginBase

  attr_reader :entries
  attr_accessor :skip_auth

  def authed?(irc)
    unless $user.caps(irc, 'faq', 'op', 'owner').any? or skip_auth
      irc.reply "You aren't allowed to use this command"
      return false
    end
    true
  end

  def initialize(*args)
    $config.merge(
    'plugins' => {
      :dir => true,
      'gitfaq' => {
        :dir => true,
        :help => 'Settings for the gitweb plugin.',
        'phrasesfile' => 'The file to read repositories from'
      }
    }
    )
    super(*args)
  end

  def load
    @filename = $config["plugins/gitfaq/phrasesfile"] || "faq.yaml"
    begin
      @entries = YAML::load_file(@filename)
    rescue Errno::ENOENT => e
      puts "GitFAQ: phrases file not found"
      @entries = {}
    end
    self
  end

  def cmd_faq(irc, line)
    puts line
    if f = @entries[line]
      irc.reply "#{line}: #{f}"
    else
      irc.reply "FAQ entry '#{line}' not found."
    end
  end

  def cmd_add_faq(irc, line)
    return unless authed?(irc)
    entry, response = line.split(" ", 2)
    if response
      @entries[entry] = response
      File.open(@filename, "w") do |f|
        f.puts @entries.to_yaml
      end
      irc.reply "FAQ entry '#{entry}' stored."
    else
      irc.reply "Invalid line"
    end
  end

end