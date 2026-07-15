require "net/http"
require "tempfile"

module Documents
  class DownloadFromUrl
    MAX_REDIRECTS = 3

    def initialize(url:, filename:)
      @url = URI(url)
      @filename = filename
    end

    def call
      response = fetch(@url, MAX_REDIRECTS)
      unless response.is_a?(Net::HTTPSuccess)
        raise DocumentAi::Error.new("Falha no download", code: "download_failed")
      end

      extension = File.extname(@filename)
      tempfile = Tempfile.new(["source-document-", extension])
      tempfile.binmode
      tempfile.write(response.body)
      tempfile.rewind

      ActionDispatch::Http::UploadedFile.new(
        tempfile: tempfile,
        filename: @filename,
        type: response["content-type"]&.split(";")&.first || Marcel::MimeType.for(tempfile)
      )
    end

    private

    def fetch(uri, redirects)
      raise DocumentAi::Error.new("Muitos redirecionamentos", code: "too_many_redirects") if redirects.negative?

      request = Net::HTTP::Get.new(uri)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.open_timeout = 10
        http.read_timeout = 60
        http.request(request)
      end

      if response.is_a?(Net::HTTPRedirection)
        return fetch(URI(response["location"]), redirects - 1)
      end

      response
    end
  end
end
