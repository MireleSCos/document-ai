module Api
  module V1
    class DocumentValidationsController < ApplicationController
      require "fileutils"

      SUPPORTED_TYPES = %w[
        rg marriage_certificate address_proof voter_registration diploma
      ].freeze

      def create
        uploaded_file = params[:file]
        return render json: { error: "file_required" }, status: :unprocessable_entity if uploaded_file.blank?

        expected_type = params[:expected_type].to_s
        unless SUPPORTED_TYPES.include?(expected_type)
          return render json: {
            error: "unsupported_document_type",
            supported_types: SUPPORTED_TYPES
          }, status: :unprocessable_entity
        end

        validation = DocumentValidation.create!(
          status: "PROCESSING",
          expected_type: expected_type,
          original_filename: uploaded_file.original_filename,
          content_type: uploaded_file.content_type,
          file_size: uploaded_file.size,
          project_id: object_id_or_nil(params[:project_id]),
          person_id: object_id_or_nil(params[:person_id]),
          shadow_mode: false
        )

        file_path = persist_uploaded_file(uploaded_file, validation.id)
        DocumentValidationAnalysisJob.perform_async(
          validation.id.to_s,
          file_path.to_s,
          {
            "candidate_name" => params[:candidate_name],
            "candidate_cpf" => params[:candidate_cpf]
          }
        )

        render json: DocumentValidationSerializer.call(validation), status: :accepted
      rescue DocumentAi::Error => error
        validation&.update!(status: "FAILED", reasons: [error.code])
        render json: { error: error.code, message: error.message }, status: error.http_status
      rescue StandardError => error
        Rails.logger.error(error.full_message)
        validation&.update!(status: "FAILED", reasons: ["unexpected_error"])
        render json: {
          error: "unexpected_error",
          message: "Não foi possível validar o documento."
        }, status: :internal_server_error
      end

      def show
        validation = DocumentValidation.find(params[:id])
        render json: DocumentValidationSerializer.call(validation)
      end

      private

      def object_id_or_nil(value)
        return nil if value.blank?
        BSON::ObjectId.from_string(value)
      rescue BSON::ObjectId::Invalid
        nil
      end

      def persist_uploaded_file(uploaded_file, validation_id)
        directory = Rails.root.join("tmp", "document_validations")
        FileUtils.mkdir_p(directory)

        extension = File.extname(uploaded_file.original_filename.to_s)
        file_path = directory.join("#{validation_id}#{extension}")

        uploaded_file.rewind
        File.open(file_path, "wb") do |file|
          IO.copy_stream(uploaded_file.tempfile, file)
        end

        file_path
      end
    end
  end
end
