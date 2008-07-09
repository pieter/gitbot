$: << File.join(File.dirname(__FILE__), "..", "..")
require 'pluginbase'
require 'lib/irc'
require 'plugins/gitweb'
require 'test/unit'
require 'ostruct'

TEST_CONFIG = File.join(File.dirname(__FILE__), "..", "..", "repositories.yaml")
$config = { "plugins/gitweb/configfile" => TEST_CONFIG}
$hooks = {}
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
    o.name = "#pieter"
    o
  end

  def reply(message)
    @message = message
  end

end

class GitwebPluginTest < Test::Unit::TestCase

  def setup
    @irc = MockIrc.new
    @web = Gitweb.new
  end

  def test_nil_irc_reply
    @web.hook_privmsg_chan(@irc, "A failed ref should output nothing: 324aabbb3434")
    assert_equal(@irc.message, nil)
  end

  def test_explicit_nil_irc_reply
    @web.hook_privmsg_chan(@irc, "A failed explicit ref should output nothing: <git nonsensebranch>.")
    assert_equal("I'm sorry, there's no such object: nonsensebranch.", @irc.message)
  end

  def test_explicit_irc_reply
    @web.hook_privmsg_chan(@irc, "A succesful lookup should not give an error: <git master>.")
    assert_match(/^\[git master\]: http.* -- .*$/, @irc.message)
  end

  def test_implicit_irc_reply
    @web.hook_privmsg_chan(@irc, "This is interesting -- 88d9f4111f185d665b8340819bd50713a4a2caf8.")
    assert_match(/^\[egit 88d9f4111\]: http.* -- .*$/, @irc.message)
  end

  def test_implicit_irc_tree_reply
    @web.hook_privmsg_chan(@irc, "This is interesting -- cc73fa2e4ea56951a75f52e15a0d4385e8e5e6b2.")
    assert_match(/^\[egit cc73fa2e4\]: http.* \[tree\]$/, @irc.message)
  end
  
  def test_explicit_path
    @web.hook_privmsg_chan(@irc, "Look at <HEAD:Documentation/git-reset.txt>!.")
    assert_match(/^\[git git-reset.txt\]: http.* \[blob\]$/, @irc.message)
  end

  def test_false_path
    @web.hook_privmsg_chan(@irc, "Look at <HEAD:nonexistingfile>!.")
    assert_equal("I'm sorry, there's no such object: HEAD:nonexistingfile.", @irc.message)
  end    
end
