require File.join(File.dirname(__FILE__), "..", "..", "testlib")

require 'git'

GIT_DIR = "/tmp/tmptestgitdir"
FileUtils.remove_dir(GIT_DIR) if File.exist?(GIT_DIR)

`mkdir #{GIT_DIR}; cd #{GIT_DIR}; git init; touch a; mkdir b; touch b/c; git add a; git commit -m "First commit"; git add b/c; git commit -m "a commit";`

class GitwebTest < Test::Unit::TestCase

  def setup
    @source = Git::Source::Local.new("file://" + GIT_DIR)
  end

  def test_false_repo
    assert_raise(Git::Source::Local::RepositoryNotFoundError) do
      Git::Source::Local.new("file:///tmp/dosutaosu")
    end
  end

  def test_matches
    assert(@source.matches?(/tmptest/))
    assert(@source.matches?(/tmptestgitdir/))
    assert(!@source.matches?(/temp-test/))
  end

  def test_name
    assert_equal("tmptestgitdir", @source.name)
  end

  def test_lookup_HEAD
    l = @source.lookup("HEAD", nil)
    assert(l)
    assert_equal(nil, l[:url])
    assert_equal("commit", l[:type])
    assert_equal("a commit", l[:subject])
  end

  def test_lookup_false_branch
    l = @source.lookup("Nonexisting branch", nil)
    assert_nil(l)
  end
  
  def test_lookup_tree
    l = @source.lookup("HEAD", "b")
    assert(l)
    assert_equal("tree", l[:type])
    assert_equal("b", l[:file])
  end
  
  def test_lookup_blob
    l = @source.lookup("HEAD", "a")
    assert(l)
    assert_equal("blob", l[:type])
    assert_equal("a", l[:file])
  end
  
  def test_create
    a = Git::Source::Source.create("file://" + GIT_DIR)
    assert(a.is_a?(Git::Source::Local))
  end
end
