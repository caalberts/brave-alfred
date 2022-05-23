#!/usr/bin/env ruby

require 'json'
require 'singleton'

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
      @profile_factory = ProfileFactory.new(command: command, home: home)
      @item_factory = ItemFactory.new(command: command, param: param)
    end

    def execute
      AlfredResponse.new(items: create_items).to_h
    end

    private

    attr_reader :home, :command, :param, :profiles, :item_factory

    def create_items
      @profiles = @profile_factory.load_profiles

      profiles.map do |profile|
        item_factory.item_for(profile)
      end
    end
  end

  class ProfileFactory
    def initialize(command:, home:)
      @command = command
      @home = home
    end

    def load_profiles
      return [IncognitoProfile.instance] if command == INCOGNITO

      glob_pattern = "#{home}/#{APPLICATION_SUPPORT_PATH}/*/#{PREFERENCES_FILE}"

      Dir.glob(glob_pattern)
         .reject { |path| path.include?('System Profile') }
         .map { |preference_path| Profile.new(preference_path) }
         .sort_by { |profile| profile.name }
    end

    private

    attr_reader :command, :home
  end

  class IncognitoProfile
    include Singleton

    def name
      'Incognito'
    end

    def directory
      ''
    end
  end

  class Profile
    GENERATED_PROFILES_MATCHER = %r{#{APPLICATION_SUPPORT_PATH}/(Default|Guest Profile|Profile [0-9]+)/#{PREFERENCES_FILE}}

    def initialize(path)
      @path = path
    end

    def name
      return @name unless @name.nil?

      file = File.open(path)

      JSON.load(file).dig('profile', 'name')
    ensure
      file.close
    end

    def directory
      @directory ||= GENERATED_PROFILES_MATCHER.match(path)[1]
    end

    private

    attr_reader :path
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
    def launcher
      "#{EXECUTABLE} #{url}--incognito"
    end
  end
end

if $PROGRAM_NAME == __FILE__
  command = ARGV[0]
  param = ARGV[1]
  puts BraveAlfred::Engine.new(command: command, param: param).execute.to_json
end
