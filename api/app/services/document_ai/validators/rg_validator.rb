module DocumentAi
  module Validators
    class RgValidator < BaseValidator
      private

      def document_type = "rg"

      def specific_reasons
        reasons = []
        reasons << "name_not_found" unless present?(extracted_fields[:full_name])
        reasons << "document_number_not_found" unless present?(extracted_fields[:rg_number]) || present?(extracted_fields[:cpf])

        if context[:candidate_name].present? &&
           extracted_fields[:full_name].present? &&
           !NamesMatch.call(context[:candidate_name], extracted_fields[:full_name])
          reasons << "candidate_name_mismatch"
        end

        reasons
      end
    end
  end
end
