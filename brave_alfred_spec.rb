require 'minitest/autorun'

require_relative './brave_alfred'

class BraveAlfredTest < Minitest::Test
  def test_execute_returns_a_hash_with_items_array
    with_stub_profiles_in_home do |home|
      result = BraveAlfred.new(home: home).execute

      assert_instance_of(Hash, result)
      assert_instance_of(Array, result[:items])
    end
  end

  def test_execute_launch_returns_as_many_items_as_there_are_profiles
    with_stub_profiles_in_home do |home|
      result = BraveAlfred.new(command: BraveAlfred::LAUNCH, home: home).execute
      items = result[:items]

      assert_equal(test_profiles.length, items.length)
    end
  end

  def test_execute_launch_returns_items_with_brave_cli_launcher
    with_stub_profiles_in_home do |home|
      result = BraveAlfred.new(command: BraveAlfred::LAUNCH, home: home).execute
      items = result[:items]

      test_profiles.each do |directory, name|
        expected_cmd = "#{BraveAlfred::EXECUTABLE} --profile-directory=\"#{directory}\""

        assert_includes(items, { title: name, subtitle: "Open Brave Browser as #{name}" , arg: expected_cmd })
      end
    end
  end

  def test_execute_launch_does_not_include_system_profile
    with_stub_profiles_in_home({ 'System Profile' => 'System'}) do |home|
      result = BraveAlfred.new(command: BraveAlfred::LAUNCH, home: home).execute
      items = result[:items]

      assert_empty(items)
    end
  end

  def test_execute_incognito_returns_items_with_brave_cli_incognito_launcher
    with_stub_profiles_in_home do |home|
      result = BraveAlfred.new(command: BraveAlfred::INCOGNITO, home: home).execute
      items = result[:items]

      test_profiles.each do |directory, name|
        expected_cmd = "#{BraveAlfred::EXECUTABLE} --profile-directory=\"#{directory}\" --incognito"

        assert_includes(items, { title: name, subtitle: "Open Brave Browser as #{name} in private" , arg: expected_cmd })
      end
    end
  end

  private

  def with_stub_profiles_in_home(profiles = test_profiles)
    Dir.mktmpdir do |dir|
      stub_brave_support_dir(dir, profiles)
      yield dir
    end
  end

  def stub_brave_support_dir(home_dir, profiles)
    support_dir = File.join(home_dir, BraveAlfred::APPLICATION_SUPPORT_PATH)

    FileUtils.mkdir_p(support_dir)

    profiles.each do |directory, name|
      profile_dir = File.join(support_dir, directory)

      FileUtils.mkdir_p(profile_dir)

      preferences = File.join(profile_dir, BraveAlfred::PREFERENCES_FILE)

      File.open(preferences, 'w+') do |file|
        JSON.dump(preference_content(name), file)
      end
    end
  end

  def preference_content(name)
    {
      profile: {
        name: name
      }
    }
  end

  def test_profiles
    @test_profiles ||= {
      'Default' => 'Batman',
      'Profile 1' => 'Robin',
      'Profile 2' => 'Cat Woman',
      'Guest Profile' => 'Guest',
    }
  end
end
