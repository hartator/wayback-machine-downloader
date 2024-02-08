require 'json'
require 'uri'

module ArchiveAPI

  def get_raw_list_from_api url, page_index, http
    request_url = URI("https://web.archive.org/cdx/search/xd")
    params = [["output", "json"], ["url", url]]
    params += parameters_for_api page_index
    request_url.query = URI.encode_www_form(params)

    begin
      json = JSON.parse(http.get(URI(request_url)).body)
      if (json[0] <=> ["timestamp","original"]) == 0
        json.shift
      end
      json
    rescue JSON::ParserError
      []
    end
  end

  def parameters_for_api page_index
    parameters = [["fl", "timestamp,original"], ["collapse", "digest"], ["gzip", "false"]]
    if !@all
      parameters.push(["filter", "statuscode:200"])
    end
    if @from_timestamp and @from_timestamp != 0
      parameters.push(["from", @from_timestamp.to_s])
    end
    if @to_timestamp and @to_timestamp != 0
      parameters.push(["to", @to_timestamp.to_s])
    end
    if page_index
      parameters.push(["page", page_index])
    end
    parameters
  end

end
