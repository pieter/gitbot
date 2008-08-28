require File.join(File.dirname(__FILE__), 'testlib')

$plugins = []
$hooks = {}


require 'plugins/gitman'

class GitManPluginTest < Test::Unit::TestCase

  def setup    
    @irc = MockIrc.new
    @web = Gitman.new
  end

  def test_nil_irc_reply
    @web.hook_privmsg_chan(@irc, "I like man git-rev-parse")
    sleep(2)
    assert_match(/Pieter: the git-rev-parse manpage can be found at http:\/\/.*/, @irc.message)
  end

  def test_implicit_with_reply
    @web.hook_privmsg_chan(@irc, "John: see man git-log")
    sleep(3)
    assert_match(/John: the git-log manpage can be found at http.*$/, @irc.message)
    @web.hook_privmsg_chan(@irc, "Jane, see man git-diff")
    sleep(3)
    assert_match(/Jane: the git-diff manpage can be found at http.*$/, @irc.message)
  end

end