module DocumentAi
  module Validators
    class DiplomaValidator < BaseValidator
      private

      def document_type = "diploma"

      def specific_reasons
        reasons = []
        reasons << "name_not_found" unless present?(extracted_fields[:full_name])
        reasons << "institution_name_not_found" unless present?(extracted_fields[:institution_name])
        reasons << "course_name_not_found" unless present?(extracted_fields[:course_name])

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
