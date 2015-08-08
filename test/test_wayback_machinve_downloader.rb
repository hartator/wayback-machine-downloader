require 'minitest/autorun'
require 'pry-rescue/minitest'
require 'wayback_machine_downloader'


class WaybackMachineDownloaderTest < Minitest::Test

  def setup
    @wayback_machine_downloader = WaybackMachineDownloader.new base_url: 'http://www.onlyfreegames.net'
  end

  def test_base_url_being_set
    assert_equal 'http://www.onlyfreegames.net', @wayback_machine_downloader.base_url
  end

  def test_file_list_curated
    assert_equal 20081120203712, @wayback_machine_downloader.file_list_curated["linux.htm"][:timestamp]
  end

  def test_file_download
    @wayback_machine_downloader.download_files
  end

end
