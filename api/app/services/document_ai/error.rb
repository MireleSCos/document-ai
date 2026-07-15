module DocumentAi
  class Error < StandardError
    attr_reader :code, :http_status

    def initialize(message, code: "document_ai_error", http_status: :unprocessable_entity)
      super(message)
      @code = code
      @http_status = http_status
    end
  end
end
