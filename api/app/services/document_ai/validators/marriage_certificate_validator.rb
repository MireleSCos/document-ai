module DocumentAi
  module Validators
    class MarriageCertificateValidator < BaseValidator
      private

      def document_type = "marriage_certificate"

      def specific_reasons
        reasons = []
        reasons << "spouse_one_name_not_found" unless present?(extracted_fields[:spouse_one_name])
        reasons << "spouse_two_name_not_found" unless present?(extracted_fields[:spouse_two_name])

        unless present?(extracted_fields[:registry_number]) || present?(extracted_fields[:registry_office])
          reasons << "registry_information_not_found"
        end

        reasons
      end
    end
  end
end
