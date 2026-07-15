require "net/http"
require "json"
require "base64"

module DocumentAi
  module Providers
    class OpenaiProvider < BaseProvider
      ENDPOINT = URI("https://api.openai.com/v1/responses")

      def initialize(api_key: ENV["OPENAI_API_KEY"], model: ENV["OPENAI_MODEL"])
        raise DocumentAi::Error.new("OPENAI_API_KEY não configurada", code: "missing_api_key") if api_key.blank?
        raise DocumentAi::Error.new("OPENAI_MODEL não configurado", code: "missing_model") if model.blank?

        @api_key = api_key
        @model = model
      end

      def analyze(images:, expected_type:, context: {})
        response = perform_request(images:, expected_type:, context:)
        payload = JSON.parse(response.body)

        unless response.is_a?(Net::HTTPSuccess)
          message = payload.dig("error", "message") || "Provider retornou HTTP #{response.code}"
          raise DocumentAi::Error.new(
            message,
            code: "provider_error",
            http_status: :bad_gateway
          )
        end

        {
          result: JSON.parse(extract_output_text(payload)),
          provider: "openai",
          model: @model,
          provider_request_id: payload["id"]
        }
      rescue JSON::ParserError => error
        raise DocumentAi::Error.new(
          "Resposta JSON inválida do provider: #{error.message}",
          code: "invalid_provider_json",
          http_status: :bad_gateway
        )
      end

      private

      def perform_request(images:, expected_type:, context:)
        request = Net::HTTP::Post.new(ENDPOINT)
        request["Authorization"] = "Bearer #{@api_key}"
        request["Content-Type"] = "application/json"
        request.body = {
          model: @model,
          store: false,
          input: [{
            role: "user",
            content: [
              {
                type: "input_text",
                text: PromptBuilder.call(expected_type:, context:)
              },
              *image_contents(images)
            ]
          }],
          text: {
            format: {
              type: "json_schema",
              name: "document_validation_analysis",
              strict: true,
              schema: DocumentSchema.json_schema
            }
          }
        }.to_json

        http = Net::HTTP.new(ENDPOINT.host, ENDPOINT.port)
        http.use_ssl = true
        http.open_timeout = 15
        http.read_timeout = 120
        http.request(request)
      end

      def image_contents(images)
        images.map do |image|
          encoded = Base64.strict_encode64(File.binread(image.fetch(:path)))
          {
            type: "input_image",
            image_url: "data:#{image.fetch(:content_type)};base64,#{encoded}",
            detail: "high"
          }
        end
      end

      def extract_output_text(payload)
        message = payload.fetch("output").find { |item| item["type"] == "message" }
        content = message&.fetch("content", [])&.find { |item| item["type"] == "output_text" }
        text = content&.fetch("text", nil)

        return text if text.present?

        raise DocumentAi::Error.new(
          "Provider não retornou output_text",
          code: "missing_provider_output",
          http_status: :bad_gateway
        )
      end
    end
  end
end
