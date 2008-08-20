$: << File.join(File.dirname(__FILE__), "..", "lib")
$: << File.join(File.dirname(__FILE__), "..")

$plugins = []
$hooks = {}


require 'fileutils'
require 'lib/pluginbase'
require 'plugins/irc'
require 'plugins/gitman'
require 'test/unit'
require 'ostruct'

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
    o.nname = "#pieter"
    o.server = server
    o
  end

  def reply(message)
    @message = message
  end

end

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