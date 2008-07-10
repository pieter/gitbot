$: << File.join(File.dirname(__FILE__), "..", "..", "lib")
require 'git'
require 'test/unit'
require 'ostruct'

class RepoTest < Test::Unit::TestCase
  
  def setup
    @source = Git::Source::Repo.new("repo:git.git")
  end
  
  def test_name
    assert_equal(@source.name, "git")
  end
  
  def test_object_url
    assert_equal(@source.object_url("HEAD", nil).to_s, "http://repo.or.cz/w/git.git/?a=object;h=HEAD")
  end
  
  def test_matches
    assert(@source.matches?(/git/))
    assert(@source.matches?(/git.git/))
  end
  
  def test_lookup_HEAD
    l = @source.lookup("HEAD", nil)
    assert(l)
    assert_equal(l[:url], "http://repo.or.cz/w/git.git/?a=commit;h=HEAD")
    assert_equal(l[:type], "commit")
    assert(l[:subject])
  end
  
  def test_lookup_tree
    l = @source.lookup("HEAD", "Documentation")
    assert(l)
    assert_match(/^http:\/\/repo.or.cz\/w\/git.git\?a=tree;f=Documentation;h=[a-z0-9]{40,40};hb=HEAD/, l[:url])
    assert_equal(l[:type], "tree")
  end
  
  def test_lookup_blob
    l = @source.lookup("HEAD", "Makefile")
    assert(l)
    assert_equal("blob", l[:type])
    assert_match(/^http:\/\/repo.or.cz\/w\/git.git\?a=blob;f=Makefile;h=[a-z0-9]{40,40};hb=HEAD/, l[:url])
  end
  
  def test_create
    a = Git::Source::Source.create("repo:git.git")
    assert(a.is_a?(Git::Source::Repo))
  end
end
