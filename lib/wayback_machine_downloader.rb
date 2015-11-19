# encoding: UTF-8

require 'open-uri'
require 'fileutils'
require_relative 'wayback_machine_downloader/tidy_bytes'
require_relative 'wayback_machine_downloader/to_regex'

class WaybackMachineDownloader

  VERSION = "0.2.0"

  attr_accessor :base_url, :timestamp, :only_filter

  def initialize params
    @base_url = params[:base_url]
    @timestamp = params[:timestamp].to_i
    @only_filter = params[:only_filter]
  end

  def backup_name
    @base_url.split('/')[2]
  end

  def backup_path
    'websites/' + backup_name + '/'
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

  def get_file_list_curated
    index_file_list_raw = open "http://web.archive.org/cdx/search/xd?url=#{@base_url}"
    all_file_list_raw = open "http://web.archive.org/cdx/search/xd?url=#{@base_url}/*"
    file_list_curated = Hash.new
    [index_file_list_raw, all_file_list_raw].each do |file|
      file.each_line do |line|
        line = line.split(' ')
        file_timestamp = line[1].to_i
        file_url = line[2]
        file_id = file_url.split('/')[3..-1].join('/')
        file_id = URI.unescape file_id
        file_id = file_id.tidy_bytes unless file_id == ""
        if file_id.nil?
          puts "Malformed file url, ignoring: #{file_url}"
        elsif @timestamp == 0 or file_timestamp <= @timestamp
          if not match_only_filter(file_url)
            puts "File url not in supplied only filter, ignoring: #{file_url}"
          elsif file_list_curated[file_id]
            unless file_list_curated[file_id][:timestamp] > file_timestamp
              file_list_curated[file_id] = {file_url: file_url, timestamp: file_timestamp}
            end
          else
            file_list_curated[file_id] = {file_url: file_url, timestamp: file_timestamp}
          end
        end
      end
    end
    file_list_curated
  end

  def get_file_list_by_timestamp
    file_list_curated = get_file_list_curated
    file_list_curated = file_list_curated.sort_by { |k,v| v[:timestamp] }.reverse
    file_list_curated.map do |file_remote_info|
      file_remote_info[1][:file_id] = file_remote_info[0]
      file_remote_info[1]
    end
  end

  def download_files
    puts "Downloading #{@base_url} to #{backup_path} from Wayback Machine..."
    puts
    file_list_by_timestamp = get_file_list_by_timestamp
    if file_list_by_timestamp.count == 0
      puts "No files to download. Possible reasons:\n\t* Accept regex didn't let any files through (Accept Regex: \"#{@accept_regex.to_s}\")\n\t* Site is not in wayback machine."
      return
    end
    count = 0
    file_list_by_timestamp.each do |file_remote_info|
      count += 1
      file_url = file_remote_info[:file_url]
      file_id = file_remote_info[:file_id]
      file_timestamp = file_remote_info[:timestamp]
      file_path_elements = file_id.split('/')
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
      unless File.exists? file_path
        begin
          structure_dir_path dir_path
          open(file_path, "wb") do |file|
            begin
              open("http://web.archive.org/web/#{file_timestamp}id_/#{file_url}") do |uri|
                file.write(uri.read)
              end
            rescue OpenURI::HTTPError => e
              puts "#{file_url} # #{e}"
              file.write(e.io.read)
            rescue StandardError => e
              puts "#{file_url} # #{e}"
            end
          end
        rescue StandardError => e
          puts "#{file_url} # #{e}"
        end
        puts "#{file_url} -> #{file_path} (#{count}/#{file_list_by_timestamp.size})"
      else
        puts "#{file_url} # #{file_path} already exists. (#{count}/#{file_list_by_timestamp.size})"
      end
    end
    puts
    puts "Download complete, saved in #{backup_path} (#{file_list_by_timestamp.size} files)"
  end

  def structure_dir_path dir_path
    begin
      FileUtils::mkdir_p dir_path unless File.exists? dir_path
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

end
