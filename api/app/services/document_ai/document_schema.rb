module DocumentAi
  class DocumentSchema
    def self.json_schema
      {
        type: "object",
        additionalProperties: false,
        properties: {
          detected_type: {
            type: "string",
            enum: %w[rg marriage_certificate address_proof unknown]
          },
          confidence: { type: "number", minimum: 0, maximum: 1 },
          document_present: { type: "boolean" },
          quality: {
            type: "object",
            additionalProperties: false,
            properties: {
              readable: { type: "boolean" },
              complete: { type: "boolean" },
              cropped: { type: "boolean" },
              blurred: { type: "boolean" },
              has_glare: { type: "boolean" }
            },
            required: %w[readable complete cropped blurred has_glare]
          },
          extracted_fields: {
            type: "object",
            additionalProperties: false,
            properties: {
              full_name: nullable_string,
              cpf: nullable_string,
              rg_number: nullable_string,
              birth_date: nullable_string,
              issue_date: nullable_string,
              issuing_authority: nullable_string,
              spouse_one_name: nullable_string,
              spouse_two_name: nullable_string,
              marriage_date: nullable_string,
              registry_number: nullable_string,
              registry_office: nullable_string,
              address: nullable_string,
              postal_code: nullable_string,
              document_date: nullable_string,
              issuer: nullable_string
            },
            required: %w[
              full_name cpf rg_number birth_date issue_date issuing_authority
              spouse_one_name spouse_two_name marriage_date registry_number
              registry_office address postal_code document_date issuer
            ]
          },
          visual_warnings: { type: "array", items: { type: "string" } },
          missing_requirements: { type: "array", items: { type: "string" } },
          summary: { type: "string" }
        },
        required: %w[
          detected_type confidence document_present quality extracted_fields
          visual_warnings missing_requirements summary
        ]
      }
    end

    def self.nullable_string
      { anyOf: [{ type: "string" }, { type: "null" }] }
    end

    private_class_method :nullable_string
  end
end
