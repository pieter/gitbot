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
    assert_match(/\[git-rev-parse\]: http:\/\/.*/, @irc.message)
  end

end