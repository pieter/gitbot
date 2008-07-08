$: << File.join(File.dirname(__FILE__), "..", "..")
require 'pluginbase'
require 'lib/irc'
require 'plugins/gitweb'
require 'test/unit'
require 'ostruct'

TEST_CONFIG = File.join(File.dirname(__FILE__), "..", "..", "repositories.yaml")

class GitwebTest < Test::Unit::TestCase

  def setup
    @runner = GitwebLoader.new(TEST_CONFIG)
  end

  def parse(message)
    @runner.parse("carnique", "#pieter", message)
  end

  def test_notexisting_parse
    assert_nil(parse("This is a nil test"))
  
    n = parse("This is a failed <git doesnotexist> test")
    assert(n && n[:failed], "Should return a failed")
  
    #n = parse("This does not exist: git::master:nofile.")
    #assert(n && n[:failed], "Should return a failed")
  end
  
  def test_ref_parse
    assert_nil(parse("this is an unexisting ref: aaabbb1242323"))
  
    h = parse("This is an existing ref: bed625540a0e1a4ba4da9962ed53c1d83d9bf509")
    assert(h, "should exist")
    assert_equal(h[:ref], "bed625540a0e1a4ba4da9962ed53c1d83d9bf509", "Should have equal hashes")
    assert_equal(h[:type], "commit")
    assert_equal(h[:reponame], "git")
    assert(h[:url] =~ /tinyurl/)
  
    h = parse("This is a ref in egit: 88d9f4111f185d665b8340819bd50713a4a2caf8.")
    assert_equal(h[:ref], "88d9f4111f185d665b8340819bd50713a4a2caf8")
    assert_equal(h[:type], "commit")
    assert_equal(h[:reponame], "egit")
  
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
  
end
