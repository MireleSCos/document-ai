class DocumentValidationSerializer
  def self.call(validation)
    {
      id: validation.id.to_s,
      status: validation.status,
      approved: validation.approved,
      expected_type: validation.expected_type,
      detected_type: validation.detected_type,
      confidence: validation.confidence,
      extracted_fields: validation.extracted_fields,
      quality: validation.quality,
      checks: validation.checks,
      reasons: validation.reasons,
      warnings: validation.warnings,
      shadow_mode: validation.shadow_mode,
      created_at: validation.created_at
    }
  end
end
