#!/usr/bin/env ruby

require 'json'

module BraveAlfred
  APPLICATION_SUPPORT_PATH = 'Library/Application Support/BraveSoftware/Brave-Browser'
  PREFERENCES_FILE = 'Preferences'
  EXECUTABLE = '"/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"'

  LAUNCH = 'launch'
  INCOGNITO = 'incognito'

  AlfredItem = Struct.new(:title, :subtitle, :arg, keyword_init: true)

  class Engine
    def initialize(command: LAUNCH, home: ENV['HOME'], param: nil)
      @command = command
      @home = home
      @param = param
      @profiles = load_profiles
    end

    def execute
      {
        items: create_items.map(&:to_h)
      }
    end

    private

    attr_reader :home, :command, :param, :profiles

    def create_items
      return [] unless command == LAUNCH || command == INCOGNITO

      profiles
        .sort_by { |profile| profile.name }
        .map do |profile|
        AlfredItem.new(
          title: profile.name,
          subtitle: subtitle_for(profile),
          arg: launcher_for(profile)
        )
      end
    end

    def load_profiles
      glob_pattern = "#{home}/#{APPLICATION_SUPPORT_PATH}/*/#{PREFERENCES_FILE}"

      Dir.glob(glob_pattern)
         .reject { |path| path.include?('System Profile') }
         .map { |preference_path| Profile.from(preference_path) }
    end

    def subtitle_for(profile)
      base = "Open Brave Browser as #{profile.name}"
      base += " in private" if command == INCOGNITO
      base
    end

    def launcher_for(profile)
      base = "#{EXECUTABLE} #{param.nil? ? '' : "\"#{param}\" " }--profile-directory=\"#{profile.directory}\""
      base += " --incognito" if command == INCOGNITO
      base
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
end

if $PROGRAM_NAME == __FILE__
  command = ARGV[0]
  param = ARGV[1]
  puts BraveAlfred.new(command: command, param: param).execute.to_json
end
