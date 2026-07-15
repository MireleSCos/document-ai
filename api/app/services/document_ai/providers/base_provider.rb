module DocumentAi
  module Providers
    class BaseProvider
      def analyze(images:, expected_type:, context: {})
        raise NotImplementedError
      end
    end
  end
end
