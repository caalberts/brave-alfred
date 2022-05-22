#!/usr/bin/env ruby

class BraveAlfred
  def initialize(home = ENV['HOME'])
    @home = home
  end

  def execute
    ''
  end
end

if $PROGRAM_NAME == __FILE__
  puts BraveAlfred.new.execute
end
