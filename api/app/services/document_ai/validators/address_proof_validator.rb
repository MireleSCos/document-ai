module DocumentAi
  module Validators
    class AddressProofValidator < BaseValidator
      MAXIMUM_AGE_IN_DAYS = 90

      private

      def document_type = "address_proof"

      def specific_reasons
        reasons = []
        reasons << "address_not_found" unless present?(extracted_fields[:address])
        reasons << "issuer_not_found" unless present?(extracted_fields[:issuer])
        reasons << "document_date_not_found" unless present?(extracted_fields[:document_date])

        date = parse_date(extracted_fields[:document_date])
        reasons << "document_expired" if date && date < MAXIMUM_AGE_IN_DAYS.days.ago.to_date
        reasons
      end

      def parse_date(value)
        Date.iso8601(value.to_s)
      rescue Date::Error
        nil
      end
    end
  end
end
