require 'minitest/autorun'
require 'wayback_machine_downloader'

class WaybackMachineDownloaderTest < Minitest::Test
  def test_english_hello
    assert_equal "Hello world! John", WaybackMachineDownloader.hi("John")
  end
end
