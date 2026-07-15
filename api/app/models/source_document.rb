# Adapte store_in e os campos ao model real da Workverse.
class SourceDocument
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: "documents"

  field :status, type: String
  field :files, type: Hash, default: {}
  field :person_id, type: BSON::ObjectId
  field :project_id, type: BSON::ObjectId
  field :type, type: String
  field :status_message, type: String
  field :classification, type: String
  field :api, type: String
end
