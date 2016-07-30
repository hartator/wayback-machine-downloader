require 'minitest/autorun'
require 'wayback_machine_downloader'

class WaybackMachineDownloaderTest < Minitest::Test

  def setup
    @wayback_machine_downloader = WaybackMachineDownloader.new base_url: 'http://www.onlyfreegames.net'
    $stdout = StringIO.new
  end

  def teardown
    FileUtils.rm_rf(@wayback_machine_downloader.backup_path)
  end

  def test_base_url_being_set
    assert_equal 'http://www.onlyfreegames.net', @wayback_machine_downloader.base_url
  end

  def test_file_list_curated
    assert_equal 20081120203712, @wayback_machine_downloader.get_file_list_curated["linux.htm"][:timestamp]
  end

  def test_file_list_by_timestamp
    file_expected = {
      file_id: "page.html",
      file_url: "http://www.onlyfreegames.net:80/page.html",
      timestamp: 20060713153753
    }
    assert_equal file_expected, @wayback_machine_downloader.get_file_list_by_timestamp[-1]
  end

  def test_file_list_only_filter_without_matches
    @wayback_machine_downloader.only_filter = 'abc123'
    assert_equal 0, @wayback_machine_downloader.get_file_list_curated.size
  end

  def test_file_list_only_filter_with_1_match
    @wayback_machine_downloader.only_filter = 'menu.html'
    assert_equal 1, @wayback_machine_downloader.get_file_list_curated.size
  end

  def test_file_list_only_filter_with_a_regex
    @wayback_machine_downloader.only_filter = '/\.(gif|je?pg|bmp)$/i'
    assert_equal 37, @wayback_machine_downloader.get_file_list_curated.size
  end

  def test_file_list_exclude_filter_without_matches
    @wayback_machine_downloader.exclude_filter = 'abc123'
    assert_equal 68, @wayback_machine_downloader.get_file_list_curated.size
  end

  def test_file_list_exclude_filter_with_1_match
    @wayback_machine_downloader.exclude_filter = 'menu.html'
    assert_equal 67, @wayback_machine_downloader.get_file_list_curated.size
  end

  def test_file_list_exclude_filter_with_a_regex
    @wayback_machine_downloader.exclude_filter = '/\.(gif|je?pg|bmp)$/i'
    assert_equal 31, @wayback_machine_downloader.get_file_list_curated.size
  end

  def test_file_download
    @wayback_machine_downloader.download_files
    linux_page = open 'websites/www.onlyfreegames.net/linux.htm'
    assert_includes linux_page.read, "Linux Games"
  end

  def test_from_timestamp_being_respected
    @wayback_machine_downloader.from_timestamp = 20050716231334
    file_url = @wayback_machine_downloader.get_file_list_curated["linux.htm"][:file_url]
    assert_equal "http://www.onlyfreegames.net/linux.htm", file_url
  end

  def test_to_timestamp_being_respected
    @wayback_machine_downloader.to_timestamp = 20050716231334
    assert_nil @wayback_machine_downloader.get_file_list_curated["linux.htm"]
  end

end
