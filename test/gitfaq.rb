$: << File.join(File.dirname(__FILE__), "..", "lib")
$: << File.join(File.dirname(__FILE__), "..")

require 'lib/pluginbase'
require 'plugins/irc'
require 'plugins/gitfaq'
require 'plugins/user'
require 'test/unit'
require 'ostruct'

TEST_PHRASES_FILE = File.join(File.dirname(__FILE__), "test_faq.yaml")
$config = { "plugins/gitfaq/phrasesfile" => TEST_PHRASES_FILE}
$hooks = {}
$commands = {}
$plugins = {}

User.new


class MockIrc

  attr_reader :message

  def puts(m)
    @message = m
  end

  def server
    o = OpenStruct.new
    o.name = "carnique"
    o
  end

  def channel
    o = OpenStruct.new
    o.nname = "#pieter"
    o.server = server
    o
  end

  def reply(message)
    @message = message
  end

end

class GitFAQPluginTest < Test::Unit::TestCase

  def setup
    File.open(TEST_PHRASES_FILE, "w") { |f| f.puts "---\nstored: This is a stored phrase" }
    @irc = MockIrc.new
    @plugin = Gitfaq.new.load
  end

  def teardown
    File.unlink(TEST_PHRASES_FILE)
  end

  def test_add_unauthorized
    @plugin.cmd_add_faq(@irc, "test dit")
    assert_equal(@irc.message, "You aren't allowed to use this command")
    assert_nil(@plugin.entries["test"])
  end

  def test_lookup_unauthorized
    assert(@plugin.entries["stored"])
    @plugin.cmd_faq(@irc, "stored")
    assert_equal("stored: This is a stored phrase", @irc.message)
  end

  def test_lookup_unknown
    assert_nil(@plugin.entries["nothing"])
    @plugin.cmd_faq(@irc, "nothing")
    assert_equal("FAQ entry 'nothing' not found.", @irc.message)
  end

  def test_add_authorized
    @plugin.skip_auth = true
    @plugin.cmd_add_faq(@irc, "test dit")
    assert_equal("FAQ entry 'test' stored.", @irc.message)
    assert_equal("dit", @plugin.entries["test"])

    @plugin.cmd_faq(@irc, "test")
    assert_equal("test: dit", @irc.message)
  end
end