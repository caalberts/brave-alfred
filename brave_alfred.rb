#!/usr/bin/env ruby

require 'json'

class BraveAlfred
  APPLICATION_SUPPORT_PATH = 'Library/Application Support/BraveSoftware/Brave-Browser'
  PREFERENCES_FILE = 'Preferences'
  EXECUTABLE = '"/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"'

  def initialize(home = ENV['HOME'])
    @home = home
  end

  def execute
    {
      items: create_items
    }
  end

  private

  attr_reader :home

  def create_items
    profiles.map do |profile|
      {
        title: profile.name,
        arg: launcher_for(profile)
      }
    end
  end

  def profiles
    glob_pattern = "#{home}/#{APPLICATION_SUPPORT_PATH}/*/#{PREFERENCES_FILE}"

    Dir.glob(glob_pattern)
       .reject { |path| path.include?('System Profile') }
       .map { |preference_path| Profile.from(preference_path) }
  end

  def launcher_for(profile)
    "#{EXECUTABLE} --profile-directory=\"#{profile.directory}\""
  end

  Profile = Struct.new(:name, :directory, keyword_init: true) do
    GENERATED_PROFILES_MATCHER = %r{#{APPLICATION_SUPPORT_PATH}/(Default|Guest Profile|Profile [0-9]+)/#{PREFERENCES_FILE}}

    def self.from(preference_path)
      directory = GENERATED_PROFILES_MATCHER.match(preference_path)[1]

      raise ArgumentError if directory.nil?

      self.new(name: parse_name(preference_path), directory: directory)
    end

    def self.parse_name(preference_path)
      file = File.open(preference_path)

      JSON.load(file).dig('profile', 'name')
    ensure
      file.close
    end
  end
end

if $PROGRAM_NAME == __FILE__
  puts BraveAlfred.new.execute.to_json
end
