$: << File.join(File.dirname(__FILE__), "..", "..", "lib")
require 'git'
require 'test/unit'
require 'ostruct'

class GitwebTest < Test::Unit::TestCase
  
  def setup
    @source = Git::Source::Gitweb.new("http://git.frim.nl/?p=gitbot.git")
  end
  
  def test_name
    assert_equal(@source.name, "gitbot")
  end
  
  def test_object_url
    assert_equal(@source.object_url("HEAD", nil).to_s, "http://git.frim.nl/?p=gitbot.git;a=object;h=HEAD")
  end
  
  def test_matches
    assert(@source.matches?(/gitbot/))
    assert(@source.matches?(/gitbot.git/))
  end
  
  def test_lookup_HEAD
    l = @source.lookup("HEAD", nil)
    assert(l)
    assert_equal(l[:url], "http://git.frim.nl/?p=gitbot.git;a=commit;h=HEAD")
    assert_equal(l[:type], "commit")
    assert(l[:subject])
  end
  
  def test_lookup_tree
    l = @source.lookup("HEAD", "lib")
    assert(l)
    assert_match(/^http:\/\/git.frim.nl\/\?p=gitbot.git;a=tree;f=lib;h=[a-z0-9]{40,40};hb=HEAD/, l[:url])
    assert_equal(l[:type], "tree")
  end
  
  def test_lookup_blob
    l = @source.lookup("HEAD", "README")
    assert(l)
    assert_equal("blob", l[:type])
    assert_match(/^http:\/\/git.frim.nl\/\?p=gitbot.git;a=blob;f=README;h=[a-z0-9]{40,40};hb=HEAD/, l[:url])
  end
  
  def test_create
    a = Git::Source::Source.create("http://git.frim.nl/?p=gitbot.git")
    assert(a.is_a?(Git::Source::Gitweb))
  end
end
