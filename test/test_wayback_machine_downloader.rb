require 'minitest/autorun'
require 'wayback_machine_downloader'

class WaybackMachineDownloaderTest < Minitest::Test

  def setup
    @wayback_machine_downloader = WaybackMachineDownloader.new(
      base_url: 'http://www.onlyfreegames.net')
    $stdout = StringIO.new
  end

  def teardown
    FileUtils.rm_rf(@wayback_machine_downloader.backup_path)
  end

  def test_base_url_being_set
    assert_equal 'http://www.onlyfreegames.net', @wayback_machine_downloader.base_url
  end

  def test_backup_name_being_set
    assert_equal 'www.onlyfreegames.net', @wayback_machine_downloader.backup_name
  end

  def test_backup_name_being_set_when_base_url_is_domain
    @wayback_machine_downloader.base_url = 'www.onlyfreegames.net'
    assert_equal 'www.onlyfreegames.net', @wayback_machine_downloader.backup_name
  end

  def test_file_list_curated
    assert_equal 20060711191226, @wayback_machine_downloader.get_file_list_curated["linux.htm"][:timestamp]
  end

  def test_file_list_by_timestamp
    file_expected = {
      file_url: "http://www.onlyfreegames.net:80/strat.html",
      timestamp: 20060111084756,
      file_id: "strat.html"
    }
    assert_equal file_expected, @wayback_machine_downloader.get_file_list_by_timestamp[-2]
  end

  def test_without_exact_url
    @wayback_machine_downloader.exact_url = false
    assert @wayback_machine_downloader.get_file_list_curated.size > 1
  end

  def test_exact_url
    @wayback_machine_downloader.exact_url = true
    assert_equal 1, @wayback_machine_downloader.get_file_list_curated.size
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

  def test_all_timestamps_being_respected
    @wayback_machine_downloader.all_timestamps = true
    assert_equal 68, @wayback_machine_downloader.get_file_list_curated.size
  end

  def test_from_timestamp_being_respected
    @wayback_machine_downloader.from_timestamp = 20050716231334
    file_url = @wayback_machine_downloader.get_file_list_curated["linux.htm"][:file_url]
    assert_equal "http://www.onlyfreegames.net:80/linux.htm", file_url
  end

  def test_to_timestamp_being_respected
    @wayback_machine_downloader.to_timestamp = 20050716231334
    assert_nil @wayback_machine_downloader.get_file_list_curated["linux.htm"]
  end

  def test_all_get_file_list_curated_size
    @wayback_machine_downloader.all = true
    assert_equal 69, @wayback_machine_downloader.get_file_list_curated.size
  end
 
  # Testing encoding conflicts needs a different base_url
  def test_nonascii_suburls_download
    @wayback_machine_downloader = WaybackMachineDownloader.new(
      base_url: 'https://en.wikipedia.org/wiki/%C3%84')
    # Once just for the downloading...
    @wayback_machine_downloader.download_files
  end

  def test_nonascii_suburls_already_present
    @wayback_machine_downloader = WaybackMachineDownloader.new(
      base_url: 'https://en.wikipedia.org/wiki/%C3%84')
    # ... twice to test the "is already present" case
    @wayback_machine_downloader.download_files
    @wayback_machine_downloader.download_files
  end

end
