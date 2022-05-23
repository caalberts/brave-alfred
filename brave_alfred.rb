#!/usr/bin/env ruby

require 'json'

module BraveAlfred
  APPLICATION_SUPPORT_PATH = 'Library/Application Support/BraveSoftware/Brave-Browser'
  PREFERENCES_FILE = 'Preferences'
  EXECUTABLE = '"/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"'

  LAUNCH = 'launch'
  INCOGNITO = 'incognito'

  AlfredResponse = Struct.new(:items, keyword_init: true) do
    def to_h
      { items: items.map(&:to_h) }
    end
  end

  AlfredItem = Struct.new(:title, :subtitle, :arg, keyword_init: true)

  class Engine
    def initialize(command: LAUNCH, home: ENV['HOME'], param: nil)
      @command = command
      @home = home
      @param = param
      @profiles = load_profiles
      @item_factory = ItemFactory.new(command: command, param: param)
    end

    def execute
      AlfredResponse.new(items: create_items).to_h
    end

    private

    attr_reader :home, :command, :param, :profiles, :item_factory

    def create_items
      profiles.map do |profile|
        item_factory.item_for(profile)
      end
    end

    def load_profiles
      glob_pattern = "#{home}/#{APPLICATION_SUPPORT_PATH}/*/#{PREFERENCES_FILE}"

      Dir.glob(glob_pattern)
         .reject { |path| path.include?('System Profile') }
         .map { |preference_path| Profile.from(preference_path) }
         .sort_by { |profile| profile.name }
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

  class ItemFactory
    def initialize(command:, param:)
      @command = command
      @param = param
    end

    def item_for(profile)
      item_class.new(profile: profile, param: param).item
    end

    private

    def item_class
      case command
      when LAUNCH then Launch
      when INCOGNITO then Incognito
      else
        raise ArgumentError
      end
    end

    attr_reader :command, :param
  end

  class Launch
    def initialize(profile:, param:)
      @profile = profile
      @param = param
    end

    def item
      AlfredItem.new(
        title: profile.name,
        subtitle: subtitle,
        arg: launcher
      )
    end

    private

    def subtitle
      "Open Brave Browser as #{profile.name}"
    end

    def launcher
      "#{EXECUTABLE} #{url}--profile-directory=\"#{profile.directory}\""
    end

    def url
      param.nil? ? '' : "\"#{param}\" "
    end

    attr_reader :profile, :param
  end

  class Incognito < Launch
    def subtitle
      super + " in private"
    end

    def launcher
      super + " --incognito"
    end
  end
end

if $PROGRAM_NAME == __FILE__
  command = ARGV[0]
  param = ARGV[1]
  puts BraveAlfred::Engine.new(command: command, param: param).execute.to_json
end
