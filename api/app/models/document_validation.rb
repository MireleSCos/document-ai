class DocumentValidation
  include Mongoid::Document
  include Mongoid::Timestamps

  STATUSES = %w[PENDING PROCESSING VALID INVALID REVIEW FAILED].freeze

  field :status, type: String, default: "PENDING"
  field :approved, type: Mongoid::Boolean
  field :expected_type, type: String
  field :detected_type, type: String
  field :confidence, type: Float

  field :original_filename, type: String
  field :content_type, type: String
  field :file_size, type: Integer
  field :source_url, type: String

  field :extracted_fields, type: Hash, default: {}
  field :quality, type: Hash, default: {}
  field :checks, type: Hash, default: {}
  field :reasons, type: Array, default: []
  field :warnings, type: Array, default: []

  field :provider, type: String
  field :model, type: String
  field :provider_request_id, type: String

  field :shadow_mode, type: Mongoid::Boolean, default: false
  field :source_document_id, type: BSON::ObjectId
  field :person_id, type: BSON::ObjectId
  field :project_id, type: BSON::ObjectId
  field :human_status, type: String
  field :human_status_message, type: String
  field :agrees_with_human, type: Mongoid::Boolean

  validates :status, inclusion: { in: STATUSES }
  validates :expected_type, presence: true

  index({ source_document_id: 1, created_at: -1 })
  index({ expected_type: 1, status: 1 })
  index({ shadow_mode: 1, agrees_with_human: 1 })
end
