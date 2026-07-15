require "fileutils"

class DocumentValidationAnalysisJob
  include Sidekiq::Job
  sidekiq_options retry: false

  def perform(validation_id, file_path, context)
    validation = DocumentValidation.find(validation_id)
    upload = build_upload(validation, file_path)

    result = DocumentAi::AnalyzeDocument.new(
      uploaded_file: upload,
      expected_type: validation.expected_type,
      context: {
        candidate_name: context["candidate_name"],
        candidate_cpf: context["candidate_cpf"]
      }
    ).call

    validation.update!(result.slice(
      :status, :approved, :detected_type, :confidence, :extracted_fields, :quality,
      :checks, :reasons, :warnings, :provider, :model, :provider_request_id
    ))
  rescue DocumentAi::Error => error
    validation&.update!(status: "FAILED", reasons: [error.code])
    Rails.logger.warn("Document validation #{validation_id} failed: #{error.code} #{error.message}")
  rescue StandardError => error
    validation&.update!(status: "FAILED", reasons: ["unexpected_error"])
    Rails.logger.error(error.full_message)
  ensure
    upload&.tempfile&.close
    FileUtils.rm_f(file_path) if file_path.present?
  end

  private

  def build_upload(validation, file_path)
    file = File.open(file_path, "rb")

    ActionDispatch::Http::UploadedFile.new(
      tempfile: file,
      filename: validation.original_filename,
      type: validation.content_type
    )
  end
end
