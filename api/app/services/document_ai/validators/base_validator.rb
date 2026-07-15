module DocumentAi
  module Validators
    class BaseValidator
      HARD_FAILURES = %w[
        document_not_detected wrong_document_type document_unreadable
        document_incomplete image_cropped image_blurred
      ].freeze

      def initialize(ai_result:, context: {})
        @ai_result = ai_result.deep_symbolize_keys
        @context = context.symbolize_keys
      end

      def call
        reasons = (general_reasons + specific_reasons).uniq
        status = calculate_status(reasons)

        {
          status:,
          approved: status == "VALID",
          reasons:,
          warnings: Array(ai_result[:visual_warnings]).uniq,
          checks: checks
        }
      end

      private

      attr_reader :ai_result, :context

      def general_reasons
        reasons = []
        reasons << "document_not_detected" unless ai_result[:document_present]
        reasons << "wrong_document_type" unless expected_type?
        reasons << "document_unreadable" unless quality[:readable]
        reasons << "document_incomplete" unless quality[:complete]
        reasons << "image_cropped" if quality[:cropped]
        reasons << "image_blurred" if quality[:blurred]
        reasons
      end

      def expected_type?
        ai_result[:detected_type] == document_type
      end

      def quality = ai_result.fetch(:quality, {})
      def extracted_fields = ai_result.fetch(:extracted_fields, {})
      def confidence = ai_result[:confidence].to_f
      def minimum_confidence = ENV.fetch("DOCUMENT_AI_MIN_CONFIDENCE", "0.90").to_f
      def present?(value) = value.to_s.strip.present?

      def calculate_status(reasons)
        return "INVALID" if reasons.any?
        return "REVIEW" if confidence < minimum_confidence
        "VALID"
      end

      def checks
        {
          expected_type_matches: expected_type?,
          readable: quality[:readable],
          complete: quality[:complete],
          confidence_sufficient: confidence >= minimum_confidence
        }
      end
    end
  end
end
