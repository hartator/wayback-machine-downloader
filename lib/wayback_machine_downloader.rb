# encoding: UTF-8

require 'thread'
require 'net/http'
require 'open-uri'
require 'fileutils'
require 'cgi'
require 'json'
require 'time'
require_relative 'wayback_machine_downloader/tidy_bytes'
require_relative 'wayback_machine_downloader/to_regex'
require_relative 'wayback_machine_downloader/archive_api'

class WaybackMachineDownloader

  include ArchiveAPI

  VERSION = "2.3.1"

  attr_accessor :base_url, :exact_url, :directory, :all_timestamps,
    :from_timestamp, :to_timestamp, :only_filter, :exclude_filter, 
    :all, :maximum_pages, :threads_count

  def initialize params
    @base_url = params[:base_url]
    @exact_url = params[:exact_url]
    @directory = params[:directory]
    @all_timestamps = params[:all_timestamps]
    @from_timestamp = params[:from_timestamp].to_i
    @to_timestamp = params[:to_timestamp].to_i
    @only_filter = params[:only_filter]
    @exclude_filter = params[:exclude_filter]
    @all = params[:all]
    @maximum_pages = params[:maximum_pages] ? params[:maximum_pages].to_i : 100
    @threads_count = params[:threads_count].to_i
  end

  def backup_name
    if @base_url.include? '//'
      @base_url.split('/')[2]
    else
      @base_url
    end
  end

  def backup_path
    if @directory
      if @directory[-1] == '/'
        @directory
      else
        @directory + '/'
      end
    else
      'websites/' + backup_name + '/'
    end
  end

  def match_only_filter file_url
    if @only_filter
      only_filter_regex = @only_filter.to_regex
      if only_filter_regex
        only_filter_regex =~ file_url
      else
        file_url.downcase.include? @only_filter.downcase
      end
    else
      true
    end
  end

  def match_exclude_filter file_url
    if @exclude_filter
      exclude_filter_regex = @exclude_filter.to_regex
      if exclude_filter_regex
        exclude_filter_regex =~ file_url
      else
        file_url.downcase.include? @exclude_filter.downcase
      end
    else
      false
    end
  end

  def get_all_snapshots_to_consider
    # Note: Passing a page index parameter allow us to get more snapshots,
    # but from a less fresh index
    print "Getting snapshot pages"
    snapshot_list_to_consider = []
    snapshot_list_to_consider += get_raw_list_from_api(@base_url, nil)
    print "."
    unless @exact_url
      @maximum_pages.times do |page_index|
        snapshot_list = get_raw_list_from_api(@base_url + '/*', page_index)
        break if snapshot_list.empty?
        snapshot_list_to_consider += snapshot_list
        print "."
      end
    end
    puts " found #{snapshot_list_to_consider.length} snaphots to consider."
    puts
    snapshot_list_to_consider
  end

  def get_file_list_curated
    file_list_curated = Hash.new
    get_all_snapshots_to_consider.each do |file_timestamp, file_url|
      next unless file_url.include?('/')
      file_id = file_url.split('/')[3..-1].join('/')
      file_id = CGI::unescape file_id 
      file_id = file_id.tidy_bytes unless file_id == ""
      if file_id.nil?
        puts "Malformed file url, ignoring: #{file_url}"
      else
        if match_exclude_filter(file_url)
          puts "File url matches exclude filter, ignoring: #{file_url}"
        elsif not match_only_filter(file_url)
          puts "File url doesn't match only filter, ignoring: #{file_url}"
        elsif file_list_curated[file_id]
          unless file_list_curated[file_id][:timestamp] > file_timestamp
            file_list_curated[file_id] = {file_url: file_url, timestamp: file_timestamp}
          end
        else
          file_list_curated[file_id] = {file_url: file_url, timestamp: file_timestamp}
        end
      end
    end
    file_list_curated
  end

  def get_file_list_all_timestamps
    file_list_curated = Hash.new
    get_all_snapshots_to_consider.each do |file_timestamp, file_url|
      next unless file_url.include?('/')
      file_id = file_url.split('/')[3..-1].join('/')
      file_id_and_timestamp = [file_timestamp, file_id].join('/')
      file_id_and_timestamp = CGI::unescape file_id_and_timestamp 
      file_id_and_timestamp = file_id_and_timestamp.tidy_bytes unless file_id_and_timestamp == ""
      if file_id.nil?
        puts "Malformed file url, ignoring: #{file_url}"
      else
        if match_exclude_filter(file_url)
          puts "File url matches exclude filter, ignoring: #{file_url}"
        elsif not match_only_filter(file_url)
          puts "File url doesn't match only filter, ignoring: #{file_url}"
        elsif file_list_curated[file_id_and_timestamp]
          puts "Duplicate file and timestamp combo, ignoring: #{file_id}" if @verbose
        else
          file_list_curated[file_id_and_timestamp] = {file_url: file_url, timestamp: file_timestamp}
        end
      end
    end
    puts "file_list_curated: " + file_list_curated.count.to_s
    file_list_curated
  end


  def get_file_list_by_timestamp
    if @all_timestamps
      file_list_curated = get_file_list_all_timestamps
      file_list_curated.map do |file_remote_info|
        file_remote_info[1][:file_id] = file_remote_info[0]
        file_remote_info[1]
      end
    else
      file_list_curated = get_file_list_curated
      file_list_curated = file_list_curated.sort_by { |k,v| v[:timestamp] }.reverse
      file_list_curated.map do |file_remote_info|
        file_remote_info[1][:file_id] = file_remote_info[0]
        file_remote_info[1]
      end
    end
  end

  def list_files
    # retrieval produces its own output
    @orig_stdout = $stdout
    $stdout = $stderr
    files = get_file_list_by_timestamp
    $stdout = @orig_stdout
    puts "["
    files[0...-1].each do |file|
      puts file.to_json + ","
    end
    puts files[-1].to_json
    puts "]"
  end

  def download_files
    start_time = Time.now
    puts "Downloading #{@base_url} to #{backup_path} from Wayback Machine archives."
    puts

    if file_list_by_timestamp.count == 0
      puts "No files to download."
      puts "Possible reasons:"
      puts "\t* Site is not in Wayback Machine Archive."
      puts "\t* From timestamp too much in the future." if @from_timestamp and @from_timestamp != 0
      puts "\t* To timestamp too much in the past." if @to_timestamp and @to_timestamp != 0
      puts "\t* Only filter too restrictive (#{only_filter.to_s})" if @only_filter
      puts "\t* Exclude filter too wide (#{exclude_filter.to_s})" if @exclude_filter
      return
    end
 
    puts "#{file_list_by_timestamp.count} files to download:"

    threads = []
    @processed_file_count = 0
    @threads_count = 1 unless @threads_count != 0
    @threads_count.times do
      threads << Thread.new do
        until file_queue.empty?
          file_remote_info = file_queue.pop(true) rescue nil
          download_file(file_remote_info) if file_remote_info
        end
      end
    end

    threads.each(&:join)
    end_time = Time.now
    puts
    puts "Download completed in #{(end_time - start_time).round(2)}s, saved in #{backup_path} (#{file_list_by_timestamp.size} files)"
  end

  def structure_dir_path dir_path
    begin
      FileUtils::mkdir_p dir_path unless File.exist? dir_path
    rescue Errno::EEXIST => e
      error_to_string = e.to_s
      puts "# #{error_to_string}"
      if error_to_string.include? "File exists @ dir_s_mkdir - "
        file_already_existing = error_to_string.split("File exists @ dir_s_mkdir - ")[-1]
      elsif error_to_string.include? "File exists - "
        file_already_existing = error_to_string.split("File exists - ")[-1]
      else
        raise "Unhandled directory restructure error # #{error_to_string}"
      end
      file_already_existing_temporary = file_already_existing + '.temp'
      file_already_existing_permanent = file_already_existing + '/index.html'
      FileUtils::mv file_already_existing, file_already_existing_temporary
      FileUtils::mkdir_p file_already_existing
      FileUtils::mv file_already_existing_temporary, file_already_existing_permanent
      puts "#{file_already_existing} -> #{file_already_existing_permanent}"
      structure_dir_path dir_path
    end
  end

  def download_file file_remote_info
    current_encoding = "".encoding
    file_url = file_remote_info[:file_url].encode(current_encoding)
    file_id = file_remote_info[:file_id]
    file_timestamp = file_remote_info[:timestamp]
    file_path_elements = file_id.split('/')
    original_file_mtime = nil
    if file_id == ""
      dir_path = backup_path
      file_path = backup_path + 'index.html'
    elsif file_url[-1] == '/' or not file_path_elements[-1].include? '.'
      dir_path = backup_path + file_path_elements[0..-1].join('/')
      file_path = backup_path + file_path_elements[0..-1].join('/') + '/index.html'
    else
      dir_path = backup_path + file_path_elements[0..-2].join('/')
      file_path = backup_path + file_path_elements[0..-1].join('/')
    end
    if Gem.win_platform?
      dir_path = dir_path.gsub(/[:*?&=<>\\|]/) {|s| '%' + s.ord.to_s(16) }
      file_path = file_path.gsub(/[:*?&=<>\\|]/) {|s| '%' + s.ord.to_s(16) }
    end
    unless File.exist? file_path
      begin
        structure_dir_path dir_path
        open(file_path, "wb") do |file|
          begin
            URI("https://web.archive.org/web/#{file_timestamp}id_/#{file_url}").open("Accept-Encoding" => "plain") do |uri|
              file.write(uri.read)
              if uri.meta.has_key?("x-archive-orig-last-modified")
                original_file_mtime = Time.parse(uri.meta["x-archive-orig-last-modified"])
              end
            end
          rescue OpenURI::HTTPError => e
            puts "#{file_url} # #{e}"
            if @all
              file.write(e.io.read)
              puts "#{file_path} saved anyway."
            end
          rescue StandardError => e
            puts "#{file_url} # #{e}"
          end
        end
        if not original_file_mtime.nil?
            File.utime(File.atime(file_path), original_file_mtime, file_path)
        end
      rescue StandardError => e
        puts "#{file_url} # #{e}"
      ensure
        if not @all and File.exist?(file_path) and File.size(file_path) == 0
          File.delete(file_path)
          puts "#{file_path} was empty and was removed."
        end
      end
      semaphore.synchronize do
        @processed_file_count += 1
        puts "#{file_url} -> #{file_path} (#{@processed_file_count}/#{file_list_by_timestamp.size})"
      end
    else
      semaphore.synchronize do
        @processed_file_count += 1
        puts "#{file_url} # #{file_path} already exists. (#{@processed_file_count}/#{file_list_by_timestamp.size})"
      end
    end
  end

  def file_queue
    @file_queue ||= file_list_by_timestamp.each_with_object(Queue.new) { |file_info, q| q << file_info }
  end

  def file_list_by_timestamp
    @file_list_by_timestamp ||= get_file_list_by_timestamp
  end

  def semaphore
    @semaphore ||= Mutex.new
  end
end
