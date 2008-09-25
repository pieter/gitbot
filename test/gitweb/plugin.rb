require File.join(File.dirname(__FILE__), "..", "testlib")

require 'plugins/gitweb'

GIT_DIR = "/tmp/tmptestgitdir"

TEST_CONFIG = File.join(File.dirname(__FILE__), "test_repos.yml")
$config = { "plugins/gitweb/configfile" => TEST_CONFIG}
$hooks = {}

class GitwebPluginTest < Test::Unit::TestCase

  def setup    
    # Create a simple repository
    FileUtils.remove_dir(GIT_DIR) if File.exist?(GIT_DIR)
    `mkdir #{GIT_DIR}; cd #{GIT_DIR}; git init; touch a; git add a; git commit -m "First commit"`

    @irc = MockIrc.new
    @web = Gitweb.new
  end

  def teardown
    FileUtils.remove_dir(GIT_DIR)
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
    assert_match(/^\[git master\]: http:\/\/tinyurl.* -- .*$/, @irc.message)
  end

  def test_implicit_irc_reply
    @web.hook_privmsg_chan(@irc, "This is interesting -- 88d9f4111f185d665b8340819bd50713a4a2caf8.")
    assert_match(/^\[egit 88d9f4111\]: http:\/\/tinyurl.* -- .*$/, @irc.message)
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

  def test_external_path
    @web.hook_privmsg_chan(@irc, "Look at <repo:etorrent.git HEAD>")
    assert_match(/^\[etorrent HEAD\]: http.* -- .*/, @irc.message)
  end
  
  def test_external_complex
    @web.hook_privmsg_chan(@irc, "<repo:linux-2.6.git 6c3a158316>")
    assert_match(/^\[linux-2.6 6c3a15831\]: http.* -- .*/, @irc.message)
  end

  def test_unacessible_repo_nil
    @web.hook_privmsg_chan(@irc, "This is local: <file://" + GIT_DIR + " HEAD>")
    assert_nil(@irc.message)
  end
  
  def test_accessible_local_repo
    @web.hook_privmsg_chan(@irc, "This is local: <tmptestgitdir HEAD>")
    assert(@irc.message)
    assert_equal("[tmptestgitdir HEAD]:  -- First commit", @irc.message)
  end

  def test_reload_Git
    class <<Git::Source::Source
      def has_reloaded
        false
      end
    end

    assert(!Git::Source::Source::has_reloaded)
    assert(@web.before_reload)
    assert_raise(NoMethodError) { Git::Source::Source::has_reloaded }
  end
end