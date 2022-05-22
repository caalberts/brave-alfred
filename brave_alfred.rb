#!/usr/bin/env ruby

require 'json'

class BraveAlfred
  APPLICATION_SUPPORT_PATH = 'Library/Application Support/BraveSoftware/Brave-Browser'
  PREFERENCES_FILE = 'Preferences'

  def initialize(home = ENV['HOME'])
    @home = home
  end

  def execute
    {
      items: []
    }
  end
end

if $PROGRAM_NAME == __FILE__
  puts BraveAlfred.new.execute.to_json
end
