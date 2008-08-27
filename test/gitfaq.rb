require File.join(File.dirname(__FILE__), 'testlib')
require 'plugins/gitfaq'
require 'plugins/user'

TEST_PHRASES_FILE = File.join(File.dirname(__FILE__), "faq-test.html")
$config = { }
$hooks = {}
$commands = {}
$plugins = {}

User.new

class Gitfaq
  FAQ_URL = TEST_PHRASES_FILE
end

class GitFAQPluginTest < Test::Unit::TestCase

  def setup
    @irc = MockIrc.new
    @plugin = Gitfaq.new.load
    sleep 0.1 # Sleep to allow the entries to load
  end

  def test_lookup_unauthorized
    assert(@plugin.entries["ssh-config"])
    @plugin.cmd_faq(@irc, "ssh-config")
    assert_equal("Pieter: You can setup a new entry in ~/.ssh/config with the right key. See #{Gitfaq::FAQ_URL}#ssh-config", @irc.message)
  end

  def test_lookup_unknown
    assert_nil(@plugin.entries["nothing"])
    @plugin.cmd_faq(@irc, "nothing")
    assert_equal("FAQ entry 'nothing' not found.", @irc.message)
  end

  def test_cmd_reload
    assert_nil(@plugin.entries["waa"])
    @plugin.entries["waa"] = "Hehe"
    assert(@plugin.entries["waa"])
    @plugin.cmd_reload(@irc, "")
    assert_equal("Reloading FAQ entries", @irc.message)
    sleep 0.1
    assert_nil(@plugin.entries["waa"])
  end

  def test_escape
    assert(@plugin.entries["space command"])
    @plugin.cmd_faq(@irc, "space command")
    assert_equal("Pieter: this is an entry with a space in it. See #{Gitfaq::FAQ_URL}#space+command", @irc.message)
  end

  def test_implicit_with_reply
    @plugin.hook_privmsg_chan(@irc, "John: see faq ssh-config")
    assert_equal("John: You can setup a new entry in ~/.ssh/config with the right key. See #{Gitfaq::FAQ_URL}#ssh-config", @irc.message)
    @plugin.hook_privmsg_chan(@irc, "Jane, see faq ssh-config")
    assert_equal("Jane: You can setup a new entry in ~/.ssh/config with the right key. See #{Gitfaq::FAQ_URL}#ssh-config", @irc.message)
  end

  def test_implicit_without_reply
    @plugin.hook_privmsg_chan(@irc, "I read faq ssh-config")
    assert_equal("Pieter: You can setup a new entry in ~/.ssh/config with the right key. See #{Gitfaq::FAQ_URL}#ssh-config", @irc.message)
  end

  def test_implicit_failed_lookup
    @plugin.hook_privmsg_chan(@irc, "The faq waaa does not exist")
    assert_equal(nil, @irc.message)
    @plugin.hook_privmsg_chan(@irc, "John: The faq waaa does not exist")
    assert_equal(nil, @irc.message)
  end

end