require File.join(File.dirname(__FILE__), "..", "testlib")

require 'git'

# Create a simple repository
GIT_DIR = "/tmp/tmptestgitdir"
FileUtils.remove_dir(GIT_DIR) if File.exist?(GIT_DIR)
`mkdir #{GIT_DIR}; cd #{GIT_DIR}; git init; touch a; git add a; git commit -m "First commit"`
`mkdir #{GIT_DIR}; cd #{GIT_DIR}; git init; touch a; git add a; git commit -m "First commit"`

TEST_CONFIG = File.join(File.dirname(__FILE__), "test_repos.yml")

class GitwebTest < Test::Unit::TestCase

  def setup
    # Create a simple repository
    FileUtils.remove_dir(GIT_DIR) if File.exist?(GIT_DIR)
    `mkdir #{GIT_DIR}; cd #{GIT_DIR}; git init; touch a; git add a; git commit -m "First commit"`

    @runner = Git.new(TEST_CONFIG)
    @channel = OpenStruct.new({:nname => "#pieter", :server => OpenStruct.new({:name => "carnique"})})
  end

  def teardown
    FileUtils.remove_dir(GIT_DIR)
  end

  def parse(message)
    @runner.parse(@channel, message)
  end

  def test_notexisting_parse
    assert_nil(parse("This is a nil test"))

    n = parse("This is a failed <git doesnotexist> test")
    assert(n && n[:failed], "Should return a failed")

    n = parse("This does not exist: <master:nofile>.")
    assert(n && n[:failed], "Should return a failed")

    n = parse("This should silently fail: I did a ref/heads/<unknowbranch>")
    assert_nil(n)

    n = parse("This should fail loudly: <git moster>")
    assert(n && n[:failed], "should fail loudly")
  end

  def test_ref_parse
    assert_nil(parse("this is an unexisting ref: aaabbb1242323"))

    h = parse("This is an existing ref: bed625540a0e1a4ba4da9962ed53c1d83d9bf509")
    assert(h, "should exist")
    assert_equal(h[:ref], "bed625540a0e1a4ba4da9962ed53c1d83d9bf509", "Should have equal hashes")
    assert_equal(h[:type], "commit")
    assert_equal(h[:reponame], "git")
    assert(h[:url] =~ /repo.or.cz/)

    h = parse("This is a ref in egit: 88d9f4111f185d665b8340819bd50713a4a2caf8.")
    assert_equal(h[:ref], "88d9f4111f185d665b8340819bd50713a4a2caf8")
    assert_equal(h[:type], "commit")
    assert_equal(h[:reponame], "egit")

    setup
    h = parse("It should also work between parenthesis (88d9f4111f185d665b8340819bd50713a4a2caf8)")
    assert_equal(h[:reponame], "egit")

    h = parse("It should also work explicitly like this <egit 88d9f4111f185d665b8340819bd50713a4a2caf8>")
    assert_equal("egit", h[:reponame])
    assert_equal(h[:ref], "88d9f4111f185d665b8340819bd50713a4a2caf8")

    h = parse("But not in another repo: <git 88d9f4111f185d665b8340819bd50713a4a2caf8>")
    assert(h && h[:failed], "Should return a failure")
  end

  def test_parse_head
    h = parse("Should parse a simple head: <HEAD>")
    assert_equal(h[:type], "commit")
    assert_equal(h[:reponame], "git")

    h = parse("And also in another repo: <egit HEAD>")
    assert_equal(h[:type], "commit")
    assert_equal(h[:reponame], "egit")

    h = parse("Should find a tag in another repo: <v0.3.0>")
    assert_equal(h[:reponame], "egit")
  end

  def test_parse_path_tree
    h = parse("should parse an explicit tree: <HEAD:Documentation>")
    assert_equal(h[:type], "tree")
    assert_equal(h[:ref], "HEAD")
    assert_equal(h[:file], "Documentation")
    assert_equal(h[:reponame], "git")
    assert(h[:url])
    puts h[:url]
  end

  def test_parse_path_blob
    h = parse("should parse an explicit file: <HEAD:Documentation/git-reset.txt>")
    assert_equal(h[:type], "blob")
    assert_equal(h[:ref], "HEAD")
    assert_equal(h[:file], "Documentation/git-reset.txt")
    assert_equal(h[:reponame], "git")
    assert(h[:url])
    puts h[:url]
  end

  def test_silence_after_once
    h = parse("SHolud parse this once: 88d9f4111f185d665b8340819bd50713a4a2caf8")
    assert(h)
    h = parse("But not twice -- 88d9f4111f185d665b8340819bd50713a4a2caf8")
    assert_nil(h)

    class <<Time
      alias old now
      def now; old + 5 * 60; end
    end

    h = parse("But it does after 5 minutes -- 88d9f4111f185d665b8340819bd50713a4a2caf8")
    assert(h)

    class <<Time; alias now old; end
  end

  def test_silence_with_unknown_repo
    h = parse("Should not give an error <when this> is being said")
    assert_nil(h)
  end

  def test_parse_weird_characters
    h = parse("Should not fail on weird refspecs like <git master^>")
    assert_nil(h)

    h = parse("Should not fail on weird refspecs like <git master~2>")
    assert_nil(h)
  end

  def test_parse_external_repo
    h = parse("Test this! <repo:git.git HEAD>")
    assert(h)
    assert_equal("commit", h[:type])
    assert_match(/repo.or.cz\/w\/git.git?/, h[:url])
    assert_equal("HEAD", h[:ref])
    assert_equal("git", h[:reponame])

    h = parse("TEst! <repo:git.git v1.5.3:Documentation>")
    assert(h)
    assert_equal("tree", h[:type])
    assert_equal("Documentation", h[:file])
    assert_equal("git", h[:reponame])
  end

  def test_parse_external_gitweb
    h = parse("This is cool: <http://git.frim.nl/?p=gitbot.git HEAD>")
    assert(h)
    assert_equal("commit", h[:type])
    assert_equal("gitbot", h[:reponame])
    assert_equal("HEAD", h[:ref])
  end

  def test_inacessible_local
    h = parse("This is local: <file://" + GIT_DIR + " HEAD>")
    assert_nil(h)
  end

  def test_local_access
    h = parse("This is a head: <tmptestgitdir HEAD>")
    assert(h)
  end
end

FileUtils.remove_dir(GIT_DIR)
