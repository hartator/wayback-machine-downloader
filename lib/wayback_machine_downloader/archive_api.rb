module ArchiveAPI

	def get_raw_list_from_api url
		request_url = "http://web.archive.org/cdx/search/xd?url="
		request_url += url
		request_url += parameters_for_api
		request_uri = URI.parse request_url
		response = Net::HTTP.get_response request_uri
		response.body
	end

	def parameters_for_api
		parameters = "&fl=timestamp,original&collapse=original"
    unless @all
      parameters += "&filter=statuscode:200"
    end
    if @from_timestamp and @from_timestamp != 0
      parameters += "&from=" + @from_timestamp.to_s
    end
    if @to_timestamp and @to_timestamp != 0
      parameters += "&to=" + @to_timestamp.to_s
    end
    parameters
  end

end