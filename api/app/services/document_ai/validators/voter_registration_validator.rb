module DocumentAi
  module Validators
    class VoterRegistrationValidator < BaseValidator
      private

      def document_type = "voter_registration"

      def specific_reasons
        reasons = []
        reasons << "name_not_found" unless present?(extracted_fields[:full_name])
        reasons << "voter_registration_number_not_found" unless present?(extracted_fields[:voter_registration_number])

        unless present?(extracted_fields[:electoral_zone]) || present?(extracted_fields[:electoral_section])
          reasons << "electoral_information_not_found"
        end

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
