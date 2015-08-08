require 'open-uri'
require 'fileutils'

class WaybackMachineDownloader

  attr_accessor :base_url

  def initialize params
    @base_url = params[:base_url]
  end

  def backup_name
    @base_url.split('/')[2]
  end

  def backup_path
    'websites/' + backup_name + '/'
  end

  def file_list_curated
    file_list_raw = open "http://web.archive.org/cdx/search/xd?url=#{@base_url}/*"
    file_list_curated = Hash.new
    file_list_raw.each_line do |line|
      line = line.split(' ')
      timestamp = line[1].to_i
      file_url = line[2]
      file_id = file_url.split('/')[3..-1].join('/')
      file_id = URI.unescape file_id
      if file_list_curated[file_id]
        unless file_list_curated[file_id][:timestamp] > timestamp
          file_list_curated[file_id] = {file_url: file_url, timestamp: timestamp}
        end
      else
        file_list_curated[file_id] = {file_url: file_url, timestamp: timestamp}
      end
    end
    file_list_curated
  end

  def download_files
    file_list_curated.each do |file_id, file_remote_info|
      timestamp = file_remote_info[:timestamp]
      file_url = file_remote_info[:file_url]
      file_path_elements = file_id.split('/')
      if file_id == ""
        dir_path = backup_path
        file_path = backup_path + 'index.html'
      elsif file_url[-1] == '/'
        dir_path = backup_path + file_path_elements[0..-1].join('/')
        file_path = backup_path + file_path_elements[0..-1].join('/') + 'index.html'
      else
        dir_path = backup_path + file_path_elements[0..-2].join('/')
        file_path = backup_path + file_path_elements[0..-1].join('/')
      end
      unless File.exists? file_path
        FileUtils::mkdir_p dir_path unless File.exists? dir_path
        open(file_path, "wb") do |file|
          begin
            open("http://web.archive.org/web/#{timestamp}id_/#{file_url}") do |uri|
              file.write(uri.read)
            end
          rescue OpenURI::HTTPError => e
            puts "#{file_url} # 404"
            file.write(e.io.read)
          end
        end
        puts "#{file_url} -> #{file_path}"
      else
        puts "#{file_url} # #{file_path} already exists."
      end
    end
  end

end
