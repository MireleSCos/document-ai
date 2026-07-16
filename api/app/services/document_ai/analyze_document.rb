module DocumentAi
  class AnalyzeDocument
    VALIDATORS = {
      "rg" => Validators::RgValidator,
      "marriage_certificate" => Validators::MarriageCertificateValidator,
      "address_proof" => Validators::AddressProofValidator,
      "voter_registration" => Validators::VoterRegistrationValidator,
      "diploma" => Validators::DiplomaValidator
    }.freeze

    def initialize(uploaded_file:, expected_type:, context: {}, provider: nil)
      @uploaded_file = uploaded_file
      @expected_type = expected_type
      @context = context
      @provider = provider || Providers::OpenaiProvider.new
    end

    def call
      validator_class = VALIDATORS[expected_type]
      raise Error.new("Tipo não suportado", code: "unsupported_document_type") unless validator_class

      preparer = FilePreparer.new(uploaded_file)
      images = preparer.call
      provider_response = provider.analyze(images:, expected_type:, context:)
      ai_result = provider_response.fetch(:result)
      decision = validator_class.new(ai_result:, context:).call

      {
        status: decision[:status],
        approved: decision[:approved],
        detected_type: ai_result["detected_type"],
        confidence: ai_result["confidence"],
        extracted_fields: ai_result["extracted_fields"],
        quality: ai_result["quality"],
        reasons: decision[:reasons],
        warnings: decision[:warnings],
        checks: decision[:checks],
        provider: provider_response[:provider],
        model: provider_response[:model],
        provider_request_id: provider_response[:provider_request_id]
      }
    ensure
      preparer&.cleanup
    end

    private

    attr_reader :uploaded_file, :expected_type, :context, :provider
  end
end
