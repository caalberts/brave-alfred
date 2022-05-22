require 'minitest/autorun'

require_relative './brave_alfred'

class BraveAlfredTest < Minitest::Test
  def test_execute_returns_a_hash_with_items_array
    with_stub_home do |home|
      result = BraveAlfred.new(home).execute

      assert_instance_of(Hash, result)
      assert_instance_of(Array, result[:items])
    end
  end

  private

  def with_stub_home
    Dir.mktmpdir do |dir|
      stub_brave_support_dir(dir)
      yield dir
    end
  end

  def stub_brave_support_dir(home_dir)
    support_dir = File.join(home_dir, BraveAlfred::APPLICATION_SUPPORT_PATH)

    FileUtils.mkdir_p(support_dir)

    %w[Default Profile\ 1 Profile\ 2].each do |profile|
      profile_dir = File.join(support_dir, profile)

      FileUtils.mkdir_p(profile_dir)

      preferences = File.join(profile_dir, BraveAlfred::PREFERENCES_FILE)

      File.open(preferences, 'w+') do |file|
        JSON.dump({ foo: 'bar' }, file)
      end
    end
  end
end
