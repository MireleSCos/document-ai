module DocumentAi
  module Providers
    class FakeProvider < BaseProvider
      def initialize(result:)
        @result = result
      end

      def analyze(images:, expected_type:, context: {})
        {
          result: @result,
          provider: "fake",
          model: "fake-model",
          provider_request_id: "fake-request"
        }
      end
    end
  end
end
