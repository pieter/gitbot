$: << File.join(File.dirname(__FILE__), "..", "lib")
$: << File.join(File.dirname(__FILE__), "..")

require 'fileutils'
require 'lib/pluginbase'
require 'plugins/irc'
require 'test/unit'
require 'ostruct'


class MockIrc < IrcWrapper

  attr_reader :message

  def initialize
  end

  def from
    "Pieter"
  end

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