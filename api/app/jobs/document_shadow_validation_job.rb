class DocumentShadowValidationJob
  include Sidekiq::Job

  def perform(document_id)
    return unless ENV.fetch("DOCUMENT_AI_SHADOW_MODE", "true") == "true"

    document = SourceDocument.find(document_id)
    expected_type = normalize_type(document.type)
    return unless expected_type

    document.files.to_h.each do |filename, file_data|
      analyze_file(document:, filename:, url: file_data["url"], expected_type:)
    end
  end

  private

  def analyze_file(document:, filename:, url:, expected_type:)
    upload = Documents::DownloadFromUrl.new(url:, filename:).call

    result = DocumentAi::AnalyzeDocument.new(
      uploaded_file: upload,
      expected_type: expected_type,
      context: {}
    ).call

    DocumentValidation.create!(
      result.slice(
        :status, :approved, :detected_type, :confidence, :extracted_fields, :quality,
        :checks, :reasons, :warnings, :provider, :model, :provider_request_id
      ).merge(
        expected_type: expected_type,
        original_filename: filename,
        content_type: upload.content_type,
        file_size: upload.size,
        source_url: url,
        shadow_mode: true,
        source_document_id: document.id,
        person_id: document.person_id,
        project_id: document.project_id,
        human_status: document.status,
        human_status_message: document.status_message,
        agrees_with_human: agrees?(result[:status], document.status)
      )
    )
  ensure
    upload&.tempfile&.close!
  end

  def agrees?(ai_status, human_status)
    return nil if ai_status == "REVIEW"
    normalized_human = human_status.to_s.upcase == "VALID" ? "VALID" : "INVALID"
    ai_status == normalized_human
  end

  def normalize_type(type)
    value = type.to_s.unicode_normalize(:nfkd).encode("ASCII", replace: "").downcase
    return "rg" if value.match?(/\brg\b|identidade|carteira de identidade/)
    return "marriage_certificate" if value.match?(/certidao.*casamento/)
    return "address_proof" if value.match?(/comprovante.*endereco|comprovante.*residencia/)
    return "voter_registration" if value.match?(/titulo.*eleitor|titulo.*eleitoral|e-titulo|eleitor/)
    return "diploma" if value.match?(/diploma|certificado.*conclusao|declaracao.*conclusao/)
    nil
  end
end
